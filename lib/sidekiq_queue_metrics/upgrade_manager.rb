require 'redlock'

module Sidekiq
  module QueueMetrics
    class UpgradeManager
      def self.logger
        @@logger ||= Logger.new(STDOUT)
      end

      # Check if an upgrade is needed and it can be done without user intervention,
      # otherwise it will fail with an exception.
      #
      # @raises [Redlock::LockError] when upgrade can't be performed because
      def self.upgrade_if_needed
        adcquire_lock do
          return unless upgrade_needed?

          v2_to_v3_upgrade
        end
      rescue Redlock::LockError
        fail 'A long running upgrade is in progress. Try restarting the application once finished'
      end

      def self.v2_to_v3_upgrade
        logger.info('Starting sidekiq_queue_metrics v3 upgrade')

        Sidekiq.redis_pool.with do |conn|
          old_collected_metrics = JSON.load(conn.get(Helpers.stats_key))
          old_collected_metrics.each do |(queue, stats)|
            logger.info("Upgrading #{queue} statistics")

            stats.each { |(stat, value)| Sidekiq::QueueMetrics::Storage.increment_stat(queue, stat, value) }

            failed_jobs_key = Helpers.build_failed_jobs_key(queue)

            if conn.exists(failed_jobs_key) && conn.type(failed_jobs_key) == 'string'
              temporal_failed_key = "_#{failed_jobs_key}"

              failed_jobs = JSON.parse(conn.get(Helpers.build_failed_jobs_key(queue)) || '[]')

              conn.rename(failed_jobs_key, temporal_failed_key)

              failed_jobs.each { |job| Sidekiq::QueueMetrics::Storage::add_failed_job(job) }

              conn.del(temporal_failed_key)
            end
          end

          conn.del(Helpers.stats_key)
        end

        logger.info("Sucessfully upgraded")
      end

      def self.upgrade_needed?
        Sidekiq.redis_pool.with { |conn| conn.exists(Helpers.stats_key) }
      end

      def self.adcquire_lock(&block)
        Sidekiq.redis_pool.with do |conn|
          lock_manager = Redlock::Client.new([conn], {
            retry_count:   5,
            retry_delay:   500,
            retry_jitter:  150,  # milliseconds
            redis_timeout: 0.1   # seconds
          })
          lock_manager.lock!('sidekiq_queue_metrics:upgrade_lock', 10000, &block)
        end
      end
    end
  end
end

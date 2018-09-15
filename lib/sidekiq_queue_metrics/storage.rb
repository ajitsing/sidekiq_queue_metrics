module Sidekiq::QueueMetrics
  class Storage
    FAILED_JOBS_KEY = 'failed_jobs'.freeze

    class << self
      def set_stats(key = stats_key, value)
        Sidekiq.redis_pool.with do |conn|
          conn.set(key, value)
        end
      end

      def get_stats(key = stats_key)
        Sidekiq.redis_pool.with do |conn|
          conn.get(key)
        end
      end

      def add_failed_job(job, max_count = 50)
        Sidekiq.redis_pool.with do |conn|
          queue = job['queue']
          failed_jobs = JSON.parse(conn.get("#{FAILED_JOBS_KEY}:#{queue}") || '[]')

          if failed_jobs.size >= max_count
            (failed_jobs.size - max_count + 1).times { failed_jobs.shift }
          end

          conn.set("#{FAILED_JOBS_KEY}:#{queue}", (failed_jobs << job).to_json)
        end
      end

      def failed_jobs(queue)
        Sidekiq.redis_pool.with do |conn|
          JSON.parse(conn.get("#{FAILED_JOBS_KEY}:#{queue}") || '[]')
        end
      end

      def stats_key
        Sidekiq::QueueMetrics.storage_location || 'queue_stats'
      end
    end
  end
end
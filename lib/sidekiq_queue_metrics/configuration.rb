module Sidekiq::QueueMetrics
  def self.init(config)
    config.server_middleware do |chain|
      chain.add Sidekiq::QueueMetrics::JobSuccessMonitor
    end

    config.death_handlers << Sidekiq::QueueMetrics::JobDeathMonitor.proc
    config.on(:startup) do
      upgrade_to_v3 if upgrade_needed?
    end
  end

  def self.upgrade_needed?
    Sidekiq.redis_pool.with { |conn| conn.exists(Helpers.stats_key) }
  end

  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  def self.upgrade_to_v3
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

  def self.storage_location=(key)
    @storage_location = key
  end

  def self.max_recently_failed_jobs=(count)
    @max_recently_failed_jobs = count
  end

  def self.max_recently_failed_jobs
    @max_recently_failed_jobs || 50
  end

  def self.storage_location
    @storage_location
  end
end

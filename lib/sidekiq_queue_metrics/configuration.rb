module Sidekiq::QueueMetrics
  def self.support_death_handlers?
    Sidekiq::VERSION >= '5.1'
  end

  def self.init(config)
    config.server_middleware do |chain|
      chain.add Sidekiq::QueueMetrics::JobSuccessMonitor
    end

    config.on(:startup) { UpgradeManager.upgrade_if_needed }

    if support_death_handlers?
      config.death_handlers << Sidekiq::QueueMetrics::JobDeathMonitor.proc
    else
      config.server_middleware do |chain|
        chain.add Sidekiq::QueueMetrics::JobDeathMiddleware
      end
    end
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

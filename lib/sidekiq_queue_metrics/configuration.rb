module Sidekiq::QueueMetrics
  def self.init(config)
    config.server_middleware do |chain|
      chain.add Sidekiq::QueueMetrics::JobSuccessMonitor
    end

    config.death_handlers << Sidekiq::QueueMetrics::JobDeathMonitor.proc
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
module Sidekiq::QueueMetrics
  def self.start_recording(config)
    config.server_middleware do |chain|
      chain.add Sidekiq::QueueMetrics::JobSuccessMonitor
    end

    config.death_handlers << Sidekiq::QueueMetrics::JobDeathMonitor.proc
  end

  def self.storage_location=(key)
    @storage_location = key
  end

  def self.storage_location
    @storage_location
  end
end
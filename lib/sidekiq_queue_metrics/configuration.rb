require_relative 'storage'

module Sidekiq::QueueMetrics
  def self.configure(config)
    config.server_middleware do |chain|
      chain.add Sidekiq::QueueMetrics::JobSuccessMonitor
    end
  end

  def self.storage_location=(key)
    @storage_location = key
  end

  def self.storage_location
    @storage_location
  end
end
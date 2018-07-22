require_relative 'monitor'

module Sidekiq::QueueMetrics
  class JobDeathMonitor < Monitor
    def self.proc
      Proc.new do |job, exception|
        queue = job['queue']
        JobDeathMonitor.new.monitor(queue)
      end
    end

    def status_counter
      'failed'
    end
  end
end
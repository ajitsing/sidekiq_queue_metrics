require_relative 'monitor'

module Sidekiq::QueueMetrics
  class JobDeathMonitor < Monitor
    def self.proc
      Proc.new do |job, exception|
        JobDeathMonitor.new.monitor(job)
      end
    end

    def monitor(job)
      super(job['queue'])
      Storage.add_failed_job(job)
    end

    def status_counter
      'failed'
    end
  end
end
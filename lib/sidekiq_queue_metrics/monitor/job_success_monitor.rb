require_relative 'monitor'

module Sidekiq::QueueMetrics
  class JobSuccessMonitor < Monitor
    def call(worker, job, queue)
      yield if block_given?
      monitor(queue)
    end

    def status_counter
      'processed'
    end
  end
end
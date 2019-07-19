require 'sidekiq'
require 'sidekiq_queue_metrics/storage'

module Sidekiq::QueueMetrics
  class Monitor
    def monitor(queue)
      Storage.increment_stat(queue, status_counter)
    end

    protected def status_counter
      fail 'This method should be implemented by child monitors'
    end
  end
end

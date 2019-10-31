module Sidekiq::QueueMetrics
  class JobDeathMiddleware
    def call(worker, msg, queue)
      call_dead_monitor(msg) if is_dead_job?(msg)

      yield if block_given?
    end

    def is_dead_job?(msg)
      msg.key?('retry_count') && msg['retry_count'] == 0
    end

    def call_dead_monitor(msg)
      Sidekiq::QueueMetrics::JobDeathMonitor.proc.call(msg, msg['error_class'])
    end
  end
end
require 'sidekiq_queue_metrics/storage'

module Sidekiq::QueueMetrics
  extend Eldritch::DSL

  class << self
    def fetch
      queues = []
      enqueued_jobs = scheduled_jobs = retry_stats = {}

      together do
        async do
          queues = Sidekiq::Queue.all.map(&:name).map(&:to_s)
          queues.each {|queue| enqueued_jobs[queue] = fetch_enqueued_jobs(queue)}
        end

        async {retry_stats = fetch_retry_stats}
        async {scheduled_jobs = fetch_scheduled_stats}
      end

      queues.reduce({}) do |stats, queue|
        stats[queue] = {
          'enqueued' => val_or_default(enqueued_jobs[queue]),
          'in_retry' => val_or_default(retry_stats[queue]),
          'scheduled' => val_or_default(scheduled_jobs[queue])
        }.merge(fetch_success_and_failed_stats(queue))

        stats
      end
    end

    def fetch_success_and_failed_stats(queue)
      default_metric_values = { 'processed' => 0, 'failed' => 0 }
      default_metric_values.merge(
        Sidekiq::QueueMetrics::Storage.get_stats(queue)
      )
    end

    def fetch_enqueued_jobs(queue)
      Sidekiq::Queue.new(queue).size
    end

    def fetch_retry_stats
      Sidekiq::RetrySet.new.group_by(&:queue).map {|queue, jobs| [queue, jobs.count]}.to_h
    end

    def fetch_scheduled_stats
      Sidekiq::ScheduledSet.new.group_by(&:queue).map {|queue, jobs| [queue, jobs.count]}.to_h
    end

    def failed_jobs(queue)
      Storage.failed_jobs(queue).reverse
    end

    private def val_or_default(val, default = 0)
      val || default
    end
  end
end

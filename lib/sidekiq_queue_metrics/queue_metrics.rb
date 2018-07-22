require 'sidekiq_queue_metrics/storage'

module Sidekiq::QueueMetrics
  class << self
    def fetch
      queues = []
      success_and_failed_stats = enqueued_jobs = retry_stats = {}
      together do
        async do
          queues = Sidekiq::Queue.all.map(&:name).map(&:to_s)
          queues.each {|queue| enqueued_jobs[queue] = fetch_enqueued_jobs(queue)}
        end

        async {success_and_failed_stats = fetch_success_and_failed_stats}
        async {retry_stats = fetch_retry_stats}
      end

      queues.map do |queue|
        stats = {'processed' => 0, 'failed' => 0}
        if success_and_failed_stats.has_key?(queue)
          stats['processed'] = val_or_default(success_and_failed_stats[queue]['processed'])
          stats['failed'] = val_or_default(success_and_failed_stats[queue]['failed'])
        end

        stats['enqueued'] = val_or_default(enqueued_jobs[queue])
        stats['in_retry'] = val_or_default(retry_stats[queue])
        {queue => stats}
      end.reduce({}, :merge)
    end

    def fetch_success_and_failed_stats
      JSON.load(Storage.get_stats || '{}')
    end

    def fetch_enqueued_jobs(queue)
      Sidekiq::Queue.new(queue).size
    end

    def fetch_retry_stats
      Sidekiq::RetrySet.new.group_by(&:queue).map {|queue, jobs| [queue, jobs.count]}.to_h
    end

    private
    def val_or_default(val, default = 0)
      val || default
    end
  end
end
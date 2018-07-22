require 'sidekiq'
require 'sidekiq_queue_metrics/storage'

module Sidekiq::QueueMetrics
  class Monitor
    def monitor(queue)
      stats = existing_stats
      stats[queue] ||= {}

      if stats[queue][status_counter].nil?
        stats[queue][status_counter] = 1
      else
        stats[queue][status_counter] += 1
      end

      Storage.set_stats(stats.to_json)
    end

    protected
    def status_counter
    end

    private
    def existing_stats
      JSON.load(Storage.get_stats || '{}')
    end
  end
end
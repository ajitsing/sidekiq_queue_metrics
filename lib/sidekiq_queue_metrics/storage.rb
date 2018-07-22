module Sidekiq::QueueMetrics
  class Storage
    class << self
      def set_stats(key = stats_key, value)
        Sidekiq.redis_pool.set(key, value)
      end

      def get_stats(key = stats_key)
        Sidekiq.redis_pool.get(key)
      end

      def stats_key
        Sidekiq::QueueMetrics.storage_location || 'queue_stats'
      end
    end
  end
end
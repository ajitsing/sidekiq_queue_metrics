module Sidekiq::QueueMetrics
  class Storage
    class << self
      def increment_stat(queue, stat, value = 1)
        Sidekiq.redis_pool.with do |conn|
          conn.hincrby(Helpers.build_queue_stats_key(queue), stat, value)
        end
      end

      def get_stats(queue)
        stats = Sidekiq.redis_pool.with do |conn|
          conn.hgetall(Helpers.build_queue_stats_key(queue))
        end

        Helpers.convert_hash_values(stats) { |value| value.to_i }
      end

      def add_failed_job(job, max_count = Sidekiq::QueueMetrics.max_recently_failed_jobs)
        queue = job['queue']

        Sidekiq.redis_pool.with do |conn|
          failed_job_key_for_queue = Helpers.build_failed_jobs_key(queue)

          conn.lpush(failed_job_key_for_queue, Sidekiq.dump_json(job))
          conn.rpop(failed_job_key_for_queue) if conn.llen(failed_job_key_for_queue) >= max_count
        end
      end

      def failed_jobs(queue)
        result = Sidekiq.redis_pool.with do |conn|
          conn.lrange(Helpers.build_failed_jobs_key(queue), 0, -1)
        end

        result.map(&Sidekiq.method(:load_json))
      end
    end
  end
end

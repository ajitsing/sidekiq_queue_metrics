module Sidekiq::QueueMetrics
  module Helpers
    FAILED_JOBS_KEY = 'failed_jobs'.freeze

    def self.build_queue_stats_key(queue)
      "#{stats_key}:#{queue}"
    end

    def self.build_failed_jobs_key(queue)
      "#{FAILED_JOBS_KEY}:#{queue}"
    end

    def self.stats_key
      Sidekiq::QueueMetrics.storage_location || 'queue_stats'
    end

    def self.convert_hash_values(original_hash, &block)
      original_hash.reduce({}) do |result, (k,v)|
        result[k] = case v
          when Array then v
          when Hash then convert_hash_values(v, &block)
          else block.(v)
          end

        result
      end
    end

    def self.build_metrics_for_view(last_metrics, current_metrics)
      current_metrics.each_with_object({}) do |(queue, metric), new_queue_metrics|
        new_queue_metrics[queue] = metric.each_with_object({}) do |(name, count), updated_metrics|
          previous_metric_value = last_metrics[queue] ? last_metrics[queue][name] : nil
          animate = !previous_metric_value.nil? && previous_metric_value != count

          updated_metrics[name] = {
            'count' => count,
            'animate' => animate
          }
        end
      end
    end
  end
end

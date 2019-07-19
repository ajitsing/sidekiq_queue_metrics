module Sidekiq::QueueMetrics
  module WebExtension
    def self.registered(app)
      view_path = File.join(File.expand_path("..", __FILE__), "views")

      app.get "/queue_metrics" do
        queue_metrics = Sidekiq::QueueMetrics.fetch

        @@last_metrics ||= queue_metrics
        @queue_metrics = Helpers.build_metrics_for_view(@@last_metrics, queue_metrics)
        @@last_metrics = queue_metrics

        render(:erb, File.read(File.join(view_path, "queues_stats.erb")))
      end

      app.get '/queue_metrics/queues/:queue/summary' do
        @queue = route_params[:queue]
        @queue_stats = Sidekiq::QueueMetrics.fetch[@queue]
        @failed_jobs = Sidekiq::QueueMetrics.failed_jobs(@queue)
        render(:erb, File.read(File.join(view_path, "queue_summary.erb")))
      end

      app.get '/queue_metrics/queues/:queue/jobs/:jid' do
        queue = route_params[:queue]
        jid = route_params[:jid]
        failed_jobs = Sidekiq::QueueMetrics.failed_jobs(queue)
        @job = failed_jobs.find {|job| job['jid'] == jid}
        render(:erb, File.read(File.join(view_path, "failed_job.erb")))
      end
    end
  end
end

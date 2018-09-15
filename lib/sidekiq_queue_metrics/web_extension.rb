module Sidekiq::QueueMetrics
  module WebExtension
    def self.registered(app)
      view_path = File.join(File.expand_path("..", __FILE__), "views")

      app.get "/queue_metrics" do
        @queue_metrics = Sidekiq::QueueMetrics.fetch
        render(:erb, File.read(File.join(view_path, "queue_metrics.erb")))
      end

      app.get '/queue/:queue_name/failed_jobs' do
        @queue = route_params[:queue_name]
        @failed_jobs = Sidekiq::QueueMetrics.failed_jobs(@queue)
        render(:erb, File.read(File.join(view_path, "failed_jobs.erb")))
      end
    end
  end
end
require 'sidekiq'
require 'sidekiq/api'
require "sidekiq/web"
require 'eldritch'

project_root = File.dirname(File.absolute_path(__FILE__))
Dir.glob(project_root + '/sidekiq_queue_metrics/**/*.rb', &method(:require))

if defined?(Sidekiq::Web)
  Sidekiq::Web.register Sidekiq::QueueMetrics::WebExtension
  Sidekiq::Web.tabs['Queue Metrics'] = 'queue_metrics'
end
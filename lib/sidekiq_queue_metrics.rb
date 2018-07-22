require 'sidekiq'
require 'sidekiq/api'
require 'eldritch'

project_root = File.dirname(File.absolute_path(__FILE__))
Dir.glob(project_root + '/sidekiq_queue_metrics/**/*.rb', &method(:require))

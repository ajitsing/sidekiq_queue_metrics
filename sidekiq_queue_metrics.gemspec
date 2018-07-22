# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative './lib/sidekiq_queue_metrics/version.rb'

Gem::Specification.new do |s|
  s.name                        =   'sidekiq_queue_metrics'
  s.version                     =   Sidekiq::QueueMetrics::VERSION
  s.summary                     =   'Records stats of each sidekiq queue and exposes APIs to retrieve them'
  s.authors                     =   ['Ajit Singh']
  s.email                       =   'jeetsingh.ajit@gamil.com'
  s.license                     =   'MIT'
  s.homepage                    =   'https://github.com/ajitsing/sidekiq_queue_metrics'

  s.files                       =   `git ls-files -z`.split("\x0")
  s.executables                 =   s.files.grep(%r{^bin/}) { |f| File.basename(f)  }
  s.test_files                  =   s.files.grep(%r{^(test|spec|features)/})
  s.require_paths               =   ["lib"]

  s.add_dependency                  'sidekiq', '>= 3.0'
  s.add_dependency                  'eldritch'
  s.add_development_dependency      "bundler", "~> 1.5"
  s.add_development_dependency      'rspec'
end

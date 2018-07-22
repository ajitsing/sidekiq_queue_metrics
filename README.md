# sidekiq_queue_metrics
Records stats of each sidekiq queue and exposes APIs to retrieve them

## Installation
Add this line to your application's Gemfile:
```ruby
gem 'sidekiq_queue_metrics'
```

## Configuration
```ruby
require 'sidekiq_queue_metrics'

Sidekiq.configure_server do |config|
  Sidekiq::QueueMetrics.init(config)
end
```

## Usage
Fetch stats of all queues:
```ruby
Sidekiq::QueueMetrics.fetch
```

Output:
```ruby
{
  "mailer_queue" => {"processed" => 5, "failed" => 1, "enqueued" => 2, "in_retry" => 0},
  "default_queue" => {"processed" => 10, "failed" => 0, "enqueued" => 1, "in_retry" => 1}
}
```

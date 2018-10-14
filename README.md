# sidekiq_queue_metrics
Records stats of each sidekiq queue and exposes APIs to retrieve them

[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/ajitsing/sidekiq_queue_metrics/graphs/commit-activity)
[![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=102)](https://opensource.org/licenses/MIT)
[![Gem Version](https://badge.fury.io/rb/sidekiq_queue_metrics.svg)](https://badge.fury.io/rb/sidekiq_queue_metrics)
[![HitCount](http://hits.dwyl.io/ajitsing/sidekiq_queue_metrics.svg)](http://hits.dwyl.io/ajitsing/sidekiq_queue_metrics)
![Gem Downloads](http://ruby-gem-downloads-badge.herokuapp.com/sidekiq_queue_metrics?type=total)
[![Build Status](https://travis-ci.org/ajitsing/sidekiq_queue_metrics.svg?branch=master)](https://travis-ci.org/ajitsing/sidekiq_queue_metrics)
[![Twitter Follow](https://img.shields.io/twitter/follow/Ajit5ingh.svg?style=social)](https://twitter.com/Ajit5ingh)

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
`sidekiq_queue_metrics` adds a new tab `Queue Metrics` in Sidekiq UI. In `Queue Metrics` tab you will see widget of all the queues with latest stats. To checkout individual queue summary click on the queue name. On queue summary page you will see all the stats of the queue along with 50 recently failed jobs. To see the details of the failed job click on the enqueued time column of the failed job row.

The failed job count is configuratble. You can configure your desired count using below config.

```ruby
Sidekiq::QueueMetrics.max_recently_failed_jobs = 100
```

<img src="https://github.com/ajitsing/ScreenShots/blob/master/sidekiq_queue_metrics/sidekiq_queue_metrics.png"/>

### Queue Summary

<img src="https://github.com/ajitsing/ScreenShots/blob/master/sidekiq_queue_metrics/queue_summary.png"/>

### Failed Job

<img src="https://github.com/ajitsing/ScreenShots/blob/master/sidekiq_queue_metrics/failed_job.png"/>

You can also use the below apis to directly consume the queue metrics.

Fetch stats of all queues:
```ruby
Sidekiq::QueueMetrics.fetch
```

Output:
```ruby
{
  "mailer_queue" => {"processed" => 5, "failed" => 1, "enqueued" => 2, "in_retry" => 0, "scheduled" => 0},
  "default_queue" => {"processed" => 10, "failed" => 0, "enqueued" => 1, "in_retry" => 1, "scheduled" => 2}
}
```

## Contributing

1. Fork it ( https://github.com/ajitsing/sidekiq_queue_metrics/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License
```LICENSE
MIT License

Copyright (c) 2018 Ajit Singh

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

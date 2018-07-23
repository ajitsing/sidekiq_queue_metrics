# sidekiq_queue_metrics
Records stats of each sidekiq queue and exposes APIs to retrieve them

[![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=102)](https://opensource.org/licenses/MIT)
[![Gem Version](https://badge.fury.io/rb/sidekiq_queue_metrics.svg)](https://badge.fury.io/rb/sidekiq_queue_metrics)
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
sidekiq_queue_metrics adds a new tab `Queue Metrics` in Sidekiq UI.

<img src="https://github.com/ajitsing/ScreenShots/blob/master/sidekiq_queue_metrics/sidekiq_queue_metrics.png"/>

You can also use the below apis to directly consume the queue metrics.

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

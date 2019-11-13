describe Sidekiq::QueueMetrics::JobDeathMiddleware do
  let(:redis_connection) { Redis.new }

  before(:all) do
    Sidekiq.redis = ConnectionPool.new { redis_connection }
  end

  before { redis_connection.flushall }

  context 'when retry_count key is not present' do
    it 'should call the job dead monitor' do
      expect_any_instance_of(Sidekiq::QueueMetrics::JobDeathMonitor).not_to receive(:monitor)

      subject.call(Class.new, {}, 'test_queue')
    end
  end

  context 'when retry_count key is greater than 0' do
    it 'should call the job dead monitor' do
      expect_any_instance_of(Sidekiq::QueueMetrics::JobDeathMonitor).not_to receive(:monitor)

      subject.call(Class.new, { 'retry_count' => 1 }, 'test_queue')
    end
  end

  context 'when retry_count key is 0' do
    it 'should call the job dead monitor' do
      expect_any_instance_of(Sidekiq::QueueMetrics::JobDeathMonitor).to receive(:monitor).with({
        'retry_count' => 0,
        'error_class' => 'StandardError'
      })

      subject.call(Class.new, {
        'retry_count' => 0,
        'error_class' => 'StandardError'
      }, 'test_queue')
    end
  end
end
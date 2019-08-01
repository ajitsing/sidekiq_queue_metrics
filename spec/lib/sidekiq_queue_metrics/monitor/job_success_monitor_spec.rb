describe Sidekiq::QueueMetrics::JobSuccessMonitor do
  let(:redis_connection) { Redis.new }

  let(:worker) { double(:worker) }
  let(:job) { double(:job) }

  before(:all) do
    Sidekiq.redis = ConnectionPool.new { redis_connection }
  end

  before { redis_connection.flushall }

  describe '#call' do
    let(:monitor) { Sidekiq::QueueMetrics::JobSuccessMonitor.new }

    context 'when stats does not exist' do
      it 'should create stats key and add stats of queue' do
        monitor.call(worker, job, 'mailer_queue')

        expect(
          Sidekiq::QueueMetrics::Storage.get_stats('mailer_queue')
        ).to eq({ 'processed' => 1 })
      end
    end

    context 'when stats exists' do
      it 'should create a new queue when it does not exist' do
        Sidekiq::QueueMetrics::Storage.increment_stat('mailer_queue', 'processed')

        monitor.call(worker, job, 'job_queue')

        expect(
          Sidekiq::QueueMetrics::Storage.get_stats('mailer_queue')
        ).to eq({ 'processed' => 1 })

        expect(
          Sidekiq::QueueMetrics::Storage.get_stats('job_queue')
        ).to eq({ 'processed' => 1 })
      end

      it 'should update existing queue' do
        Sidekiq::QueueMetrics::Storage.increment_stat('mailer_queue', 'processed')

        monitor.call(worker, job, 'mailer_queue')

        expect(
          Sidekiq::QueueMetrics::Storage.get_stats('mailer_queue')
        ).to eq({ 'processed' => 2 })
      end

      it 'should create failed counter when other counters exists' do
        Sidekiq::QueueMetrics::Storage.increment_stat('mailer_queue', 'failed')

        monitor.call(worker, job, 'mailer_queue')

        expect(
          Sidekiq::QueueMetrics::Storage.get_stats('mailer_queue')
        ).to eq({ 'processed' => 1, 'failed' => 1 })
      end
    end
  end
end

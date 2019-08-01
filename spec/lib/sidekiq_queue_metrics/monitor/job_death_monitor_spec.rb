describe Sidekiq::QueueMetrics::JobDeathMonitor do
  let(:redis_connection) { Redis.new }

  before(:all) do
    Sidekiq.redis = ConnectionPool.new { redis_connection }
  end

  before { redis_connection.flushall }

  describe '#call' do
    let(:job) {{'queue' => 'mailer_queue'}}
    let(:monitor) { Sidekiq::QueueMetrics::JobDeathMonitor.proc }

    context 'when stats does not exist' do
      it 'should create stats key and add stats of queue' do
        monitor.call(job)

        expect(
          Sidekiq::QueueMetrics::Storage.get_stats('mailer_queue')
        ).to eq({ 'failed' => 1 })
      end

      it 'should add the job to the failed jobs list' do
        monitor.call(job)

        expect(
          Sidekiq::QueueMetrics::Storage.failed_jobs('mailer_queue')
        ).to eql([job])
      end
    end

    context 'when stats exists' do
      it 'should create a new queue when it does not exist' do
        Sidekiq::QueueMetrics::Storage.increment_stat('mailer_queue', 'failed')

        job_queue = {'queue' => 'job_queue'}

        monitor.call(job_queue)

        expect(
          Sidekiq::QueueMetrics::Storage.get_stats('mailer_queue')
        ).to eq({ 'failed' => 1 })

        expect(
          Sidekiq::QueueMetrics::Storage.get_stats('job_queue')
        ).to eq({ 'failed' => 1 })
      end

      it 'should update existing queue' do
        Sidekiq::QueueMetrics::Storage.increment_stat('mailer_queue', 'failed')

        monitor.call(job)

        expect(
          Sidekiq::QueueMetrics::Storage.get_stats('mailer_queue')
        ).to eq({ 'failed' => 2 })
      end

      it 'should create failed counter when other counters exists' do
        Sidekiq::QueueMetrics::Storage.increment_stat('mailer_queue', 'processed')

        monitor.call(job)

        expect(
          Sidekiq::QueueMetrics::Storage.get_stats('mailer_queue')
        ).to eq({ 'processed' => 1, 'failed' => 1 })
      end
    end
  end
end

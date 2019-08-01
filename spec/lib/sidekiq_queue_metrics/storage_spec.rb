describe Sidekiq::QueueMetrics::Storage do
  let(:redis_connection) { Redis.new }
  let(:queue) { 'mailer_queue' }
  let(:job) { {'queue' => queue, 'args' => [1]} }

  before(:all) do
    Sidekiq.redis = ConnectionPool.new { redis_connection }
  end

  before { redis_connection.flushall }

  describe '#add_failed_job' do
    it 'should add first failed job' do
      expect do
        Sidekiq::QueueMetrics::Storage.add_failed_job(job)
      end.to change{ Sidekiq::QueueMetrics::Storage.failed_jobs(queue).length }.from(0).to(1)
    end

    it 'should add failed job to existing jobs' do
      Sidekiq::QueueMetrics::Storage.add_failed_job(job)

      expect do
        Sidekiq::QueueMetrics::Storage.add_failed_job({'queue' => queue, 'args' => [2]})
      end.to change{ Sidekiq::QueueMetrics::Storage.failed_jobs(queue).length }.from(1).to(2)
    end

    it 'should delete old job when failed jobs limit has reached' do
      Sidekiq::QueueMetrics::Storage.add_failed_job(job)
      Sidekiq::QueueMetrics::Storage.add_failed_job({'queue' => queue, 'args' => [2]})

      expect do
        Sidekiq::QueueMetrics::Storage.add_failed_job({'queue' => queue, 'args' => [3]}, 2)
      end.to_not change { Sidekiq::QueueMetrics::Storage.failed_jobs(queue).length }
    end
  end

  describe '#failed_jobs' do
    context 'when failed jobs are not present' do
      it 'should return failed jobs for a given queue' do
        expect(Sidekiq::QueueMetrics::Storage.failed_jobs(queue)).to be_empty
      end
    end

    context 'when failed jobs are present' do
      it 'should return failed jobs for a given queue' do
        Sidekiq::QueueMetrics::Storage.add_failed_job(job)

        expect(Sidekiq::QueueMetrics::Storage.failed_jobs(queue)).to eq([job])
      end
    end
  end
end

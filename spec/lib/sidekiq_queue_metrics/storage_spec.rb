describe Sidekiq::QueueMetrics::Storage do
  class MockRedisPool
    attr_reader :conn

    def initialize(conn)
      @conn = conn
    end

    def with
      yield conn
    end
  end

  let(:mock_redis_conn) {double(:connection)}
  let(:mock_redis_pool) {MockRedisPool.new(mock_redis_conn)}

  describe '#add_failed_job' do
    it 'should add first failed job' do
      job = {'queue' => 'mailer_queue'}
      expect(Sidekiq).to receive(:redis_pool).and_return(mock_redis_pool)
      expect(mock_redis_conn).to receive(:get).with("failed_jobs:mailer_queue").and_return(nil)

      expect(mock_redis_conn).to receive(:set).with("failed_jobs:mailer_queue", [job].to_json)

      Sidekiq::QueueMetrics::Storage.add_failed_job(job)
    end

    it 'should add failed job to existing jobs' do
      key = "failed_jobs:mailer_queue"
      new_job = {'queue' => 'mailer_queue', 'args' => [1]}
      existing_jobs = [{'queue' => 'mailer_queue', 'args' => [2]}]

      expect(Sidekiq).to receive(:redis_pool).and_return(mock_redis_pool)
      expect(mock_redis_conn).to receive(:get).with(key).and_return(existing_jobs.to_json)

      expect(mock_redis_conn).to receive(:set).with(key, [existing_jobs.first, new_job].to_json)

      Sidekiq::QueueMetrics::Storage.add_failed_job(new_job)
    end

    it 'should delete old job when failed jobs limit has reached' do
      key = "failed_jobs:mailer_queue"
      new_job = {'queue' => 'mailer_queue', 'args' => [1]}
      oldest_job = {'queue' => 'mailer_queue', 'args' => [2]}
      older_job = {'queue' => 'mailer_queue', 'args' => [3]}

      existing_jobs = [oldest_job, older_job]

      expect(Sidekiq).to receive(:redis_pool).and_return(mock_redis_pool)
      expect(mock_redis_conn).to receive(:get).with(key).and_return(existing_jobs.to_json)

      expect(mock_redis_conn).to receive(:set).with(key, [older_job, new_job].to_json)

      Sidekiq::QueueMetrics::Storage.add_failed_job(new_job, 2)
    end
  end

  describe '#failed_jobs' do
    context 'when failed jobs are not present' do
      it 'should return failed jobs for a given queue' do
        queue = 'mailer_queue'
        expect(Sidekiq).to receive(:redis_pool).and_return(mock_redis_pool)

        expect(mock_redis_conn).to receive(:get).with("failed_jobs:#{queue}").and_return(nil)

        expect(Sidekiq::QueueMetrics::Storage.failed_jobs(queue)).to be_empty
      end
    end

    context 'when failed jobs are present' do
      it 'should return failed jobs for a given queue' do
        queue = 'mailer_queue'
        jobs = [{'queue' => 'mailer_queue', 'args' => [1]}]
        expect(Sidekiq).to receive(:redis_pool).and_return(mock_redis_pool)

        expect(mock_redis_conn).to receive(:get).with("failed_jobs:#{queue}").and_return(jobs.to_json)

        expect(Sidekiq::QueueMetrics::Storage.failed_jobs(queue)).to eq(jobs)
      end
    end
  end
end
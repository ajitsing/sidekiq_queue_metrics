describe Sidekiq::QueueMetrics do
  let(:redis_connection) { Redis.new }

  before(:all) do
    Sidekiq.redis = ConnectionPool.new { redis_connection }
  end

  before { redis_connection.flushall }

  describe 'upgrading to v3' do
    let(:old_queue_stats) {{
      'mailer_queue' => {
        'failed' => 1,
        'processed' => 3
      },
      'other_queue' => {
        'failed' => 1,
        'processed' => 143
      }
    }}

    let(:failed_jobs_mailer_queue) {
      [{ 'queue' => 'mailer_queue', 'args' => [1]}]
    }

    let(:failed_jobs_other_queue) {
      [{ 'queue' => 'other_queue', 'args' => [2]}]
    }

    describe '.upgrade_to_v3' do
      before do
        redis_connection.set(Sidekiq::QueueMetrics::Helpers.stats_key, JSON.generate(old_queue_stats))
        redis_connection.set(Sidekiq::QueueMetrics::Helpers.build_failed_jobs_key('mailer_queue'), JSON.generate(failed_jobs_mailer_queue))
        redis_connection.set(Sidekiq::QueueMetrics::Helpers.build_failed_jobs_key('other_queue'), JSON.generate(failed_jobs_other_queue))
      end

      it 'should delete the old stats key' do
        Sidekiq::QueueMetrics.upgrade_to_v3

        expect(redis_connection.exists(Sidekiq::QueueMetrics::Helpers.stats_key)).to be_falsey
      end

      it 'should set the previous values into the new stats format' do
        Sidekiq::QueueMetrics.upgrade_to_v3

        mailer_queue_stats = Sidekiq::QueueMetrics::Storage.get_stats('mailer_queue')
        other_queue_stats = Sidekiq::QueueMetrics::Storage.get_stats('other_queue')

        expect(mailer_queue_stats['processed']).to be(3)
        expect(mailer_queue_stats['failed']).to be(1)

        expect(other_queue_stats['processed']).to be(143)
        expect(other_queue_stats['failed']).to be(1)
      end

      it 'should add the failed jobs into the same key with new format' do
        Sidekiq::QueueMetrics.upgrade_to_v3

        expect(Sidekiq::QueueMetrics::Storage.failed_jobs('mailer_queue')).to eql(failed_jobs_mailer_queue)
        expect(Sidekiq::QueueMetrics::Storage.failed_jobs('other_queue')).to eql(failed_jobs_other_queue)
      end

      it 'should delete temporal failed jobs keys' do
        mailer_temporal_key =  "_#{Sidekiq::QueueMetrics::Helpers.build_failed_jobs_key('mailer_queue')}"
        other_temporal_key =  "_#{Sidekiq::QueueMetrics::Helpers.build_failed_jobs_key('other_queue')}"

        Sidekiq::QueueMetrics.upgrade_to_v3

        expect(redis_connection.exists(mailer_temporal_key)).to be_falsey
        expect(redis_connection.exists(other_temporal_key)).to be_falsey
      end
    end

    describe '.upgrade_needed?' do
      it 'should be true if the old queue stats key exists' do
        redis_connection.set(Sidekiq::QueueMetrics::Helpers.stats_key, JSON.generate(old_queue_stats))

        expect(Sidekiq::QueueMetrics.upgrade_needed?).to be_truthy
      end

      it 'should be false if the old queue stats key is not set' do
        expect(Sidekiq::QueueMetrics.upgrade_needed?).to be_falsey
      end
    end
  end

  describe '#fetch' do
    before(:each) do
      queues = [OpenStruct.new(name: :mailer_queue), OpenStruct.new(name: :heavy_jobs_queue)]
      expect(Sidekiq::Queue).to receive(:all).and_return(queues)
    end

    it 'should fetch current queue stats' do
      Sidekiq::QueueMetrics::Storage.increment_stat('mailer_queue', 'processed', 2)
      Sidekiq::QueueMetrics::Storage.increment_stat('mailer_queue', 'failed')
      Sidekiq::QueueMetrics::Storage.increment_stat('heavy_jobs_queue', 'processed')

      jobs_in_retry_queue = [
        OpenStruct.new(queue: 'mailer_queue'),
        OpenStruct.new(queue: 'heavy_jobs_queue')
      ]
      scheduled_jobs = [
        OpenStruct.new(queue: 'mailer_queue'),
        OpenStruct.new(queue: 'heavy_jobs_queue')
      ]

      expect(Sidekiq::RetrySet).to receive(:new).and_return(jobs_in_retry_queue)
      expect(Sidekiq::ScheduledSet).to receive(:new).and_return(scheduled_jobs)

      expect(Sidekiq::Queue).to receive(:new).with('mailer_queue').and_return(OpenStruct.new(size: 1))
      expect(Sidekiq::Queue).to receive(:new).with('heavy_jobs_queue').and_return(OpenStruct.new(size: 1))

      queue_stats = Sidekiq::QueueMetrics.fetch

      expect(queue_stats['mailer_queue']['processed']).to eq(2)
      expect(queue_stats['mailer_queue']['failed']).to eq(1)
      expect(queue_stats['mailer_queue']['enqueued']).to eq(1)
      expect(queue_stats['mailer_queue']['in_retry']).to eq(1)
      expect(queue_stats['mailer_queue']['scheduled']).to eq(1)

      expect(queue_stats['heavy_jobs_queue']['processed']).to eq(1)
      expect(queue_stats['heavy_jobs_queue']['failed']).to eq(0)
      expect(queue_stats['heavy_jobs_queue']['enqueued']).to eq(1)
      expect(queue_stats['heavy_jobs_queue']['in_retry']).to eq(1)
      expect(queue_stats['heavy_jobs_queue']['scheduled']).to eq(1)
    end

    it 'should have default value as zero' do
      Sidekiq::QueueMetrics::Storage.increment_stat('mailer_queue', 'processed', 2)
      Sidekiq::QueueMetrics::Storage.increment_stat('heavy_jobs_queue', 'failed')

      scheduled_jobs = jobs_in_retry_queue = []

      expect(Sidekiq::RetrySet).to receive(:new).and_return(jobs_in_retry_queue)
      expect(Sidekiq::ScheduledSet).to receive(:new).and_return(scheduled_jobs)

      expect(Sidekiq::Queue).to receive(:new).with('mailer_queue').and_return(OpenStruct.new(size: 0))
      expect(Sidekiq::Queue).to receive(:new).with('heavy_jobs_queue').and_return(OpenStruct.new(size: 0))

      queue_stats = Sidekiq::QueueMetrics.fetch

      expect(queue_stats['mailer_queue']['processed']).to eq(2)
      expect(queue_stats['mailer_queue']['failed']).to be_zero
      expect(queue_stats['mailer_queue']['enqueued']).to be_zero
      expect(queue_stats['mailer_queue']['in_retry']).to be_zero
      expect(queue_stats['mailer_queue']['scheduled']).to be_zero
    end

    it 'should return Sidekiq::QueueMetrics for all sidekiq queues' do
      jobs_in_retry_queue = scheduled_jobs = []

      expect(Sidekiq::RetrySet).to receive(:new).and_return(jobs_in_retry_queue)
      expect(Sidekiq::ScheduledSet).to receive(:new).and_return(scheduled_jobs)
      expect(Sidekiq::Queue).to receive(:new).with('mailer_queue').and_return(OpenStruct.new(size: 0))
      expect(Sidekiq::Queue).to receive(:new).with('heavy_jobs_queue').and_return(OpenStruct.new(size: 0))

      queue_stats = Sidekiq::QueueMetrics.fetch

      expect(queue_stats['mailer_queue']['processed']).to be_zero
      expect(queue_stats['mailer_queue']['failed']).to be_zero
      expect(queue_stats['mailer_queue']['enqueued']).to be_zero
      expect(queue_stats['mailer_queue']['in_retry']).to be_zero
      expect(queue_stats['mailer_queue']['scheduled']).to be_zero

      expect(queue_stats['heavy_jobs_queue']['processed']).to be_zero
      expect(queue_stats['heavy_jobs_queue']['failed']).to be_zero
      expect(queue_stats['heavy_jobs_queue']['enqueued']).to be_zero
      expect(queue_stats['heavy_jobs_queue']['in_retry']).to be_zero
      expect(queue_stats['heavy_jobs_queue']['scheduled']).to be_zero
    end
  end

  describe '#failed_jobs' do
    it 'should return failed jobs for a queue' do
      queue = 'default_queue'

      job_1 = {'queue' => queue, 'args' => [1]}
      job_2 = {'queue' => queue, 'args' => [2]}

      Sidekiq::QueueMetrics::Storage.add_failed_job(job_1)
      Sidekiq::QueueMetrics::Storage.add_failed_job(job_2)

      expect(Sidekiq::QueueMetrics.failed_jobs(queue)).to eq([job_1, job_2])
    end
  end
end

describe Sidekiq::QueueMetrics do
  describe '#fetch' do
    before(:each) do
      queues = [OpenStruct.new(name: :mailer_queue), OpenStruct.new(name: :heavy_jobs_queue)]
      expect(Sidekiq::Queue).to receive(:all).and_return(queues)
    end

    it 'should fetch current queue stats' do
      stats = {mailer_queue: {processed: 2, failed: 1}, heavy_jobs_queue: {processed: 1, failed: 0}}
      jobs_in_retry_queue = [OpenStruct.new(queue: 'mailer_queue'), OpenStruct.new(queue: 'heavy_jobs_queue')]
      scheduled_jobs = [OpenStruct.new(queue: 'mailer_queue'), OpenStruct.new(queue: 'heavy_jobs_queue')]

      expect(Sidekiq::QueueMetrics::Storage).to receive(:get_stats).and_return(stats.to_json)
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
      stats = {mailer_queue: {processed: 2}, heavy_jobs_queue: {failed: 1}}
      scheduled_jobs = jobs_in_retry_queue = []

      expect(Sidekiq::QueueMetrics::Storage).to receive(:get_stats).and_return(stats.to_json)
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

      expect(Sidekiq::QueueMetrics::Storage).to receive(:get_stats).and_return(nil)
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
end
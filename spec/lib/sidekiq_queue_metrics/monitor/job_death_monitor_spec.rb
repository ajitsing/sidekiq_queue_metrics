describe Sidekiq::QueueMetrics::JobDeathMonitor do
  describe '#call' do
    let(:job) {{'queue' => 'mailer_queue'}}
    let(:exception) {double('exception')}
    let(:monitor) {Sidekiq::QueueMetrics::JobDeathMonitor.proc}

    context 'when stats does not exist' do
      it 'should create stats key and add stats of queue' do
        expect(Sidekiq::QueueMetrics::Storage).to receive(:get_stats).and_return(nil)
        expect(Sidekiq::QueueMetrics::Storage).to receive(:set_stats).with({mailer_queue: {failed: 1}}.to_json)
        expect(Sidekiq::QueueMetrics::Storage).to receive(:add_failed_job).with(job)

        monitor.call(job)
      end
    end

    context 'when stats exists' do
      it 'should create a new queue when it does not exist' do
        job_queue = {'queue' => 'job_queue'}
        existing_stats = {mailer_queue: {failed: 1}}.to_json
        expected_stats = {mailer_queue: {failed: 1}, job_queue: {failed: 1}}.to_json

        expect(Sidekiq::QueueMetrics::Storage).to receive(:get_stats).and_return(existing_stats)
        expect(Sidekiq::QueueMetrics::Storage).to receive(:set_stats).with(expected_stats)
        expect(Sidekiq::QueueMetrics::Storage).to receive(:add_failed_job).with(job_queue)

        monitor.call(job_queue)
      end

      it 'should update existing queue' do
        existing_stats = {mailer_queue: {failed: 1}}.to_json
        expected_stats = {mailer_queue: {failed: 2}}.to_json

        expect(Sidekiq::QueueMetrics::Storage).to receive(:get_stats).and_return(existing_stats)
        expect(Sidekiq::QueueMetrics::Storage).to receive(:set_stats).with(expected_stats)
        expect(Sidekiq::QueueMetrics::Storage).to receive(:add_failed_job).with(job)

        monitor.call(job)
      end

      it 'should create failed counter when other counters exists' do
        existing_stats = {mailer_queue: {processed: 1}}.to_json
        expected_stats = {mailer_queue: {processed: 1, failed: 1}}.to_json

        expect(Sidekiq::QueueMetrics::Storage).to receive(:get_stats).and_return(existing_stats)
        expect(Sidekiq::QueueMetrics::Storage).to receive(:set_stats).with(expected_stats)
        expect(Sidekiq::QueueMetrics::Storage).to receive(:add_failed_job).with(job)

        monitor.call(job)
      end
    end
  end
end
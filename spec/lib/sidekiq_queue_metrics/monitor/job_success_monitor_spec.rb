describe Sidekiq::QueueMetrics::JobSuccessMonitor do
  describe '#call' do
    let(:job) {double('job')}
    let(:worker) {double('worker')}
    let(:monitor) {Sidekiq::QueueMetrics::JobSuccessMonitor.new}

    context 'when stats does not exist' do
      it 'should create stats key and add stats of queue' do
        expect(Sidekiq::QueueMetrics::Storage).to receive(:get_stats).and_return(nil)
        expect(Sidekiq::QueueMetrics::Storage).to receive(:set_stats).with({mailer_queue: {processed: 1}}.to_json)

        monitor.call(worker, job, 'mailer_queue')
      end
    end

    context 'when stats exists' do
      it 'should create a new queue when it does not exist' do
        existing_stats = {mailer_queue: {processed: 1}}.to_json
        expected_stats = {mailer_queue: {processed: 1}, job_queue: {processed: 1}}.to_json

        expect(Sidekiq::QueueMetrics::Storage).to receive(:get_stats).and_return(existing_stats)
        expect(Sidekiq::QueueMetrics::Storage).to receive(:set_stats).with(expected_stats)

        monitor.call(worker, job, 'job_queue')
      end

      it 'should update existing queue' do
        existing_stats = {mailer_queue: {processed: 1}}.to_json
        expected_stats = {mailer_queue: {processed: 2}}.to_json

        expect(Sidekiq::QueueMetrics::Storage).to receive(:get_stats).and_return(existing_stats)
        expect(Sidekiq::QueueMetrics::Storage).to receive(:set_stats).with(expected_stats)

        monitor.call(worker, job, 'mailer_queue')
      end

      it 'should create failed counter when other counters exists' do
        existing_stats = {mailer_queue: {failed: 1}}.to_json
        expected_stats = {mailer_queue: {failed: 1, processed: 1}}.to_json

        expect(Sidekiq::QueueMetrics::Storage).to receive(:get_stats).and_return(existing_stats)
        expect(Sidekiq::QueueMetrics::Storage).to receive(:set_stats).with(expected_stats)

        monitor.call(worker, job, 'mailer_queue')
      end
    end
  end
end
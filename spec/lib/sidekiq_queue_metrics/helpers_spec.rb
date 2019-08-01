describe Sidekiq::QueueMetrics::Helpers do
  describe '.build_queue_stats_key' do
    context 'with default storage location' do
      it 'should return the name of the key where metrics are stored for a given queue' do
        expect(subject.build_queue_stats_key('test')).to eql('queue_stats:test')
      end
    end

    context 'with a different storage location' do
      before { Sidekiq::QueueMetrics.storage_location = 'different_storage_location' }
      after  { Sidekiq::QueueMetrics.storage_location = nil}

      it 'should return the name of the key where metrics are stored for a given queue' do
        expect(subject.build_queue_stats_key('test')).to eql('different_storage_location:test')
      end
    end
  end

  describe '.build_failed_jobs_key' do
    it 'should return the name of the key where failed jobs are stored for a given queue' do
      expect(subject.build_failed_jobs_key('test')).to eql('failed_jobs:test')
    end
  end

  describe '.build_metrics_for_view' do
    context 'when there is no changes' do
      let(:last_metrics) {{
        'mailer_queue' => {
          'processed' => 3
        }
      }}
      let(:current_metrics) {{
        'mailer_queue' => {
          'processed' => 3
        }
      }}

      it 'should add an animate key and a count with the same metric value' do
        expected_result = {
          'mailer_queue' => {
            'processed' => { 'count' => 3, 'animate' => false }
          }
        }

        expect(
          subject.build_metrics_for_view(last_metrics, current_metrics)
        ).to eql(expected_result)
      end
    end

    context 'when only values are changed' do
      let(:last_metrics) {{
        'mailer_queue' => {
          'processed' => 3
        }
      }}
      let(:current_metrics) {{
        'mailer_queue' => {
          'processed' => 4
        }
      }}

      it 'should add an animate key and a count with the last metric value' do
        expected_result = {
          'mailer_queue' => {
            'processed' => { 'count' => 4, 'animate' => true }
          }
        }

        expect(
          subject.build_metrics_for_view(last_metrics, current_metrics)
        ).to eql(expected_result)
      end
    end

    context' when a new queue is added' do
      let(:last_metrics) {{
        'mailer_queue' => {
          'processed' => 3
        }
      }}
      let(:current_metrics) {{
        'mailer_queue' => {
          'processed' => 4
        },
        'new_queue' => {
          'failed' => 1
        }
      }}

      it 'should add the new queue' do
        expected_result = {
          'mailer_queue' => {
            'processed' => { 'count' => 4, 'animate' => true }
          },
          'new_queue' => {
            'failed' => { 'count' => 1, 'animate' => false }
          }
        }

        expect(
          subject.build_metrics_for_view(last_metrics, current_metrics)
        ).to eql(expected_result)
      end
    end
  end
end

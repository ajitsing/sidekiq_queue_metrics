describe Sidekiq::QueueMetrics::UpgradeManager do
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

    describe '.v2_to_v3_upgrade' do
      before do
        redis_connection.set(Sidekiq::QueueMetrics::Helpers.stats_key, JSON.generate(old_queue_stats))
        redis_connection.set(Sidekiq::QueueMetrics::Helpers.build_failed_jobs_key('mailer_queue'), JSON.generate(failed_jobs_mailer_queue))
        redis_connection.set(Sidekiq::QueueMetrics::Helpers.build_failed_jobs_key('other_queue'), JSON.generate(failed_jobs_other_queue))
      end

      it 'should delete the old stats key' do
        Sidekiq::QueueMetrics::UpgradeManager.v2_to_v3_upgrade

        expect(redis_connection.exists?(Sidekiq::QueueMetrics::Helpers.stats_key)).to be_falsey
      end

      it 'should set the previous values into the new stats format' do
        Sidekiq::QueueMetrics::UpgradeManager.v2_to_v3_upgrade

        mailer_queue_stats = Sidekiq::QueueMetrics::Storage.get_stats('mailer_queue')
        other_queue_stats = Sidekiq::QueueMetrics::Storage.get_stats('other_queue')

        expect(mailer_queue_stats['processed']).to be(3)
        expect(mailer_queue_stats['failed']).to be(1)

        expect(other_queue_stats['processed']).to be(143)
        expect(other_queue_stats['failed']).to be(1)
      end

      it 'should add the failed jobs into the same key with new format' do
        Sidekiq::QueueMetrics::UpgradeManager.v2_to_v3_upgrade

        expect(Sidekiq::QueueMetrics::Storage.failed_jobs('mailer_queue')).to eql(failed_jobs_mailer_queue)
        expect(Sidekiq::QueueMetrics::Storage.failed_jobs('other_queue')).to eql(failed_jobs_other_queue)
      end

      it 'should delete temporal failed jobs keys' do
        mailer_temporal_key =  "_#{Sidekiq::QueueMetrics::Helpers.build_failed_jobs_key('mailer_queue')}"
        other_temporal_key  =  "_#{Sidekiq::QueueMetrics::Helpers.build_failed_jobs_key('other_queue')}"

        Sidekiq::QueueMetrics::UpgradeManager.v2_to_v3_upgrade

        expect(redis_connection.exists?(mailer_temporal_key)).to be_falsey
        expect(redis_connection.exists?(other_temporal_key)).to be_falsey
      end
    end

    describe '.upgrade_needed?' do
      it 'should be true if the old queue stats key exists' do
        redis_connection.set(Sidekiq::QueueMetrics::Helpers.stats_key, JSON.generate(old_queue_stats))

        expect(Sidekiq::QueueMetrics::UpgradeManager.upgrade_needed?).to be_truthy
      end

      it 'should be false if the old queue stats key is not set' do
        expect(Sidekiq::QueueMetrics::UpgradeManager.upgrade_needed?).to be_falsey
      end
    end
  end
end


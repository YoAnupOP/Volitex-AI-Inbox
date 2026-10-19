require 'rails_helper'
require 'socket'

RSpec.describe 'Campaign worker heartbeat' do # rubocop:disable RSpec/DescribeClass -- executable health script, not a class
  let(:client) { instance_double(Redis) }
  let(:path) { Rails.root.join('script/production/campaign_worker_health.rb') }

  before do
    allow(Redis).to receive(:new).and_return(client)
    allow(client).to receive(:smembers).with('processes').and_return(['worker'])
    allow(client).to receive(:hget).with('worker', 'info').and_return({ hostname: Socket.gethostname, queues: ['campaigns'] }.to_json)
    allow(client).to receive(:hget).with('worker', 'beat').and_return(Time.now.to_f.to_s)
  end

  it 'accepts the current host fresh campaign heartbeat' do
    with_modified_env REDIS_URL: 'redis://127.0.0.1:6379/13' do
      expect { load path }.not_to raise_error
    end
  end

  it 'rejects stale workers' do
    allow(client).to receive(:hget).with('worker', 'beat').and_return(2.minutes.ago.to_f.to_s)
    with_modified_env REDIS_URL: 'redis://127.0.0.1:6379/13' do
      expect { load path }.to raise_error(SystemExit)
    end
  end

  it 'accepts the ordinary worker only for its explicitly selected queue' do
    allow(client).to receive(:hget).with('worker', 'info').and_return({ hostname: Socket.gethostname, queues: ['critical'] }.to_json)
    with_modified_env REDIS_URL: 'redis://127.0.0.1:6379/13', SIDEKIQ_HEALTH_QUEUE: 'critical' do
      expect { load path }.not_to raise_error
    end
  end

  it 'rejects another host even when its queue and heartbeat match' do
    allow(client).to receive(:hget).with('worker', 'info').and_return({ hostname: 'other-worker', queues: ['campaigns'] }.to_json)
    with_modified_env REDIS_URL: 'redis://127.0.0.1:6379/13' do
      expect { load path }.to raise_error(SystemExit)
    end
  end

  it 'does not mistake the ordinary worker for a campaign worker' do
    allow(client).to receive(:hget).with('worker', 'info').and_return({ hostname: Socket.gethostname, queues: ['critical'] }.to_json)
    with_modified_env REDIS_URL: 'redis://127.0.0.1:6379/13' do
      expect { load path }.to raise_error(SystemExit)
    end
  end
end

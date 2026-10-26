require 'rails_helper'

RSpec.describe Channels::Instagram::ConnectionHealthSchedulerJob do
  it 'queues renewal for an inactive inbox whose token is approaching expiry' do
    channel = create(:channel_instagram)
    channel.update!(token_refreshed_at: 50.days.ago, expires_at: 5.days.from_now, subscription_verified_at: Time.current)
    expect { described_class.perform_now }.to have_enqueued_job(Channels::Instagram::ConnectionHealthJob).with(channel)
  end

  it 'reconciles stale subscriptions even when tokens are far from expiry' do
    channel = create(:channel_instagram)
    channel.update!(subscription_verified_at: 2.days.ago)
    expect { described_class.perform_now }.to have_enqueued_job(Channels::Instagram::ConnectionHealthJob).with(channel)
  end

  it 'leaves a recently verified connection alone' do
    channel = create(:channel_instagram)
    channel.update!(subscription_verified_at: Time.current)
    expect { described_class.perform_now }.not_to have_enqueued_job(Channels::Instagram::ConnectionHealthJob).with(channel)
  end
end

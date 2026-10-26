require 'rails_helper'

RSpec.describe Channels::Instagram::ConnectionHealthJob do
  let(:channel) { create(:channel_instagram, instagram_id: '12345', access_token: 'test-token') }
  let(:subscription) do
    stub_request(:post, 'https://graph.instagram.com/v22.0/12345/subscribed_apps')
      .with(query: { access_token: 'test-token', subscribed_fields: 'messages,message_reactions,messaging_seen,messaging_postbacks,comments' })
      .to_return(status: 200, body: { success: true }.to_json)
  end

  before do
    channel
  end

  it 'restores and verifies required account subscriptions without message traffic' do
    subscription
    described_class.perform_now(channel)
    expect(channel.reload.subscription_verified_at).to be_within(2.seconds).of(Time.current)
    expect(subscription).to have_been_requested.once
  end

  it 'does not treat an HTTP 200 with success false as a healthy subscription' do
    stub_request(:post, %r{12345/subscribed_apps}).to_return(status: 200, body: { success: false }.to_json)
    expect { described_class.perform_now(channel) }.to have_enqueued_job(described_class)
    expect(channel.reload.subscription_verified_at).to be_nil
  end

  it 'recovers an interrupted reconnect only after verifying its new subscription' do
    subscription
    channel.prompt_reauthorization!
    described_class.perform_now(channel)
    expect(channel.reload).not_to be_reauthorization_required
    expect(channel.subscription_verified_at).to be_present
  end

  it 'keeps terminal permission failures marked for reconnect' do
    stub_request(:post, %r{12345/subscribed_apps}).to_return(status: 403, body: { error: { code: 200 } }.to_json)
    described_class.perform_now(channel)
    expect(channel.reload).to be_reauthorization_required
  end

  it 'alerts after bounded transient retries without replacing a valid credential' do
    stub_request(:post, %r{12345/subscribed_apps}).to_return(status: 503, body: '{}')
    job = described_class.new(channel)
    expect(channel).to receive(:notify_connection_failure)
    4.times { job.perform_now }
    expect(channel.reload[:access_token]).to eq('test-token')
    expect(channel).not_to be_reauthorization_required
  end
end

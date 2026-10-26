require 'rails_helper'

RSpec.describe Instagram::RefreshOauthTokenService do
  let(:channel) { create(:channel_instagram, access_token: 'original-token') }
  let(:service) { described_class.new(channel: channel) }
  let(:refresh) do
    stub_request(:get, 'https://graph.instagram.com/refresh_access_token')
      .with(query: { access_token: 'original-token', grant_type: 'ig_refresh_token' })
      .to_return(status: 200, body: { access_token: 'renewed-token', expires_in: 5_184_000 }.to_json)
  end

  before do
    channel.update!(expires_at: 5.days.from_now, token_refreshed_at: 25.hours.ago)
  end

  it 'renews a valid old token and persists its own clock despite recent metadata changes' do
    refresh
    channel.update!(updated_at: Time.current)
    expect(service.refresh!).to eq('renewed-token')
    expect(channel.reload.token_refreshed_at).to be_within(2.seconds).of(Time.current)
    expect(channel.expires_at).to be_within(2.seconds).of(60.days.from_now)
  end

  it 'does not renew a token younger than 24 hours even if updated_at is old' do
    channel.update!(token_refreshed_at: 12.hours.ago, updated_at: 30.days.ago)
    expect(service.access_token).to eq('original-token')
    expect(WebMock).not_to have_requested(:get, /refresh_access_token/)
  end

  it 'reloads stale instances before renewing so only one refresh occurs' do
    refresh
    stale = Channel::Instagram.find(channel.id)
    service.refresh!
    expect(described_class.new(channel: stale).refresh!).to eq('renewed-token')
    expect(refresh).to have_been_requested.once
  end

  it 'does not overwrite a token supplied by reconnect after this instance was loaded' do
    refresh
    Channel::Instagram.find(channel.id).update!(access_token: 'reconnected-token', expires_at: 60.days.from_now)
    expect(service.refresh!).to eq('reconnected-token')
    expect(refresh).not_to have_been_requested
  end

  it 'marks an expired token for reconnect without calling Meta or notifying repeatedly' do
    channel.update!(expires_at: 1.hour.ago)
    expect(channel).to receive(:prompt_reauthorization!).once.and_call_original
    2.times { expect(service.access_token).to be_nil }
    expect(channel).to be_reauthorization_required
    expect(WebMock).not_to have_requested(:get, /refresh_access_token/)
  end

  it 'marks revoked authorization immediately and never returns the revoked token' do
    stub_request(:get, /refresh_access_token/).to_return(status: 400, body: { error: { code: 190, message: 'secret-token' } }.to_json)
    expect { service.refresh! }.to raise_error(Instagram::GraphClient::Error)
    expect(service.access_token).to be_nil
    expect(channel).to be_reauthorization_required
  end

  it 'retains a valid credential during transient failures while scheduled refresh raises a sanitized error' do
    stub_request(:get, /refresh_access_token/).to_return(status: 503, body: 'secret-token')
    expect(service.access_token).to eq('original-token')
    expect(channel).not_to be_reauthorization_required
    expect { service.refresh! }.to raise_error(Instagram::GraphClient::Error, /HTTP 503/)
  end

  it 'rejects malformed successful renewal without changing credentials or expiry' do
    stub_request(:get, /refresh_access_token/).to_return(status: 200, body: { expires_in: 0 }.to_json)
    expiry = channel.reload.expires_at
    expect { service.refresh! }.to raise_error(Instagram::GraphClient::Error)
    expect(channel.reload[:access_token]).to eq('original-token')
    expect(channel.expires_at).to eq(expiry)
  end
end

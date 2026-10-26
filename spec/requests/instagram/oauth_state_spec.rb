require 'rails_helper'

RSpec.describe 'Instagram OAuth browser and tenant binding', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:token_exchange) do
    stub_request(:post, 'https://api.instagram.com/oauth/access_token')
      .to_return(status: 200, body: { access_token: 'short-token', user_id: '12345',
                                      permissions: Instagram::IntegrationHelper::REQUIRED_SCOPES.join(',') }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_APP_SECRET', nil).and_return('instagram-state-test-secret')
    token_exchange
    stub_request(:get, 'https://graph.instagram.com/access_token')
      .with(query: hash_including(grant_type: 'ig_exchange_token', access_token: 'short-token'))
      .to_return(status: 200, body: { access_token: 'long-token', expires_in: 5_184_000 }.to_json)
    stub_request(:get, 'https://graph.instagram.com/v22.0/me')
      .with(query: hash_including(access_token: 'long-token'))
      .to_return(status: 200, body: { user_id: '12345', username: 'test_business' }.to_json)
    stub_request(:post, 'https://graph.instagram.com/v22.0/12345/subscribed_apps')
      .with(query: hash_including(access_token: 'long-token'))
      .to_return(status: 200, body: { success: true }.to_json)
  end

  it 'completes a browser-bound connect and rejects replay before another token exchange' do
    post "/api/v1/accounts/#{account.id}/instagram/authorization", headers: administrator.create_new_auth_token, as: :json
    state = Rack::Utils.parse_query(URI.parse(response.parsed_body.fetch('url')).query).fetch('state')
    expect { get '/instagram/callback', params: { code: 'test-code', state: state } }.to change(Channel::Instagram, :count).by(1)
    expect(response).to have_http_status(:redirect)
    expect(Channel::Instagram.last.subscription_verified_at).to be_present
    get '/instagram/callback', params: { code: 'test-code', state: state }
    expect(response).to have_http_status(:unauthorized)
    expect(token_exchange).to have_been_requested.once
  end

  it 'rejects a stolen authorization URL opened in another browser' do
    post "/api/v1/accounts/#{account.id}/instagram/authorization", headers: administrator.create_new_auth_token, as: :json
    state = Rack::Utils.parse_query(URI.parse(response.parsed_body.fetch('url')).query).fetch('state')
    other_browser = ActionDispatch::Integration::Session.new(Rails.application)
    other_browser.get '/instagram/callback', params: { code: 'test-code', state: state }
    expect(other_browser.response).to have_http_status(:unauthorized)
    expect(token_exchange).not_to have_been_requested
    get '/instagram/callback', params: { code: 'test-code', state: state }
    expect(response).to have_http_status(:redirect)
    expect(token_exchange).to have_been_requested.once
  end

  it 'accepts the documented Meta data-array token response with its actual permission grants' do
    stub_request(:post, 'https://api.instagram.com/oauth/access_token')
      .to_return(status: 200, body: { data: [{ access_token: 'short-token', user_id: '12345',
                                               permissions: Instagram::IntegrationHelper::REQUIRED_SCOPES.join(',') }] }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    post "/api/v1/accounts/#{account.id}/instagram/authorization", headers: administrator.create_new_auth_token, as: :json
    state = Rack::Utils.parse_query(URI.parse(response.parsed_body.fetch('url')).query).fetch('state')
    expect { get '/instagram/callback', params: { code: 'test-code', state: state } }.to change(Channel::Instagram, :count).by(1)
    expect(response).to have_http_status(:redirect)
    expect(Channel::Instagram.last.subscription_verified_at).to be_present
  end

  it 'does not authorize reconnecting another tenant inbox' do
    other_channel = create(:channel_instagram)
    post "/api/v1/accounts/#{account.id}/instagram/authorization", params: { inbox_id: other_channel.inbox.id },
                                                                   headers: administrator.create_new_auth_token, as: :json
    expect(response).to have_http_status(:not_found)
    expect(token_exchange).not_to have_been_requested
  end
end

require 'rails_helper'

RSpec.describe Instagram::GraphClient do
  let(:client) { described_class.new('private-test-token') }

  it 'uses the configured version and comma-separated subscription fields' do
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_API_VERSION', 'v22.0').and_return('v23.0')
    request = stub_request(:post, 'https://graph.instagram.com/v23.0/123/subscribed_apps')
              .with(query: { access_token: 'private-test-token', subscribed_fields: 'messages,comments' })
              .to_return(status: 200, body: { success: true }.to_json)
    expect(client.request(:post, '123/subscribed_apps', params: { subscribed_fields: 'messages,comments' })).to eq('success' => true)
    expect(request).to have_been_requested.once
  end

  it 'removes provider body and parser causes from failures' do
    stub_request(:get, /refresh_access_token/).to_return(status: 503, body: 'private-test-token')
    expect { client.request(:get, 'refresh_access_token', versioned: false) }.to raise_error(described_class::Error) { |error|
      expect(error.message).not_to include('private-test-token')
      expect(error.cause).to be_nil
    }
  end

  it 'filters OAuth state and authorization codes from Rails parameter logs' do
    filtered = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter('state' => 'private-state',
                                                                                                     'code' => 'private-code')
    expect(filtered).to eq('state' => '[FILTERED]', 'code' => '[FILTERED]')
  end
end

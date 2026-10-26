require 'rails_helper'

RSpec.describe Instagram::IntegrationHelper do
  include described_class

  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:browser_nonce) { 'private-browser-binding' }
  let(:secret) { 'test-instagram-secret' }
  let(:token) { generate_instagram_token(account.id, 'onboarding', user_id: admin.id, browser_nonce: browser_nonce, inbox_id: 42) }

  before do
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_APP_SECRET', nil).and_return(secret)
  end

  it 'binds tenant, administrator, operation and target inbox in expiring state' do
    payload = consume_instagram_state!(token, browser_nonce: browser_nonce)
    expect(payload.slice('sub', 'user_id', 'inbox_id', 'return_to')).to eq('sub' => account.id, 'user_id' => admin.id,
                                                                           'inbox_id' => 42, 'return_to' => 'onboarding')
    expect(payload['exp'] - payload['iat']).to eq(600)
  end

  it 'consumes a state exactly once' do
    consume_instagram_state!(token, browser_nonce: browser_nonce)
    expect { consume_instagram_state!(token, browser_nonce: browser_nonce) }.to raise_error(described_class::InvalidState)
  end

  it 'rejects a different browser without consuming the initiating browser state' do
    expect { consume_instagram_state!(token, browser_nonce: 'other-browser') }.to raise_error(described_class::InvalidState)
    expect(consume_instagram_state!(token, browser_nonce: browser_nonce)['sub']).to eq(account.id)
  end

  it 'rejects expired state' do
    issued = token
    travel 11.minutes do
      expect { consume_instagram_state!(issued, browser_nonce: browser_nonce) }.to raise_error(described_class::InvalidState)
    end
  end

  it 'rejects the historical signed format without expiry' do
    old = JWT.encode({ sub: account.id, iat: 1.year.ago.to_i }, secret, 'HS256')
    expect { consume_instagram_state!(old, browser_nonce: browser_nonce) }.to raise_error(described_class::InvalidState)
  end

  it 'rechecks administrator membership at callback time' do
    issued = token
    admin.account_users.find_by!(account: account).update!(role: :agent)
    expect { consume_instagram_state!(issued, browser_nonce: browser_nonce) }.to raise_error(described_class::InvalidState)
  end

  it 'rejects altered signed state' do
    altered = "#{token}tampered"
    expect { consume_instagram_state!(altered, browser_nonce: browser_nonce) }.to raise_error(described_class::InvalidState)
  end
end

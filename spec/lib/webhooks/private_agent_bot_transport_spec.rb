require 'rails_helper'

RSpec.describe Webhooks::PrivateAgentBotTransport do
  let(:account) { create(:account) }
  let(:url) { 'http://n8n-private.test:5678/webhook/account-one' }
  let!(:bot) { create(:agent_bot, account: account, outgoing_url: url) }
  let(:payload) { { account: { id: account.id }, event: 'message_created' } }
  let(:binding) { { account_id: account.id, agent_bot_id: bot.id, url: url, ip_addresses: ['172.28.8.10'] } }
  let(:transport) { described_class.for(url: url, payload: payload, secret: bot.secret) }

  around do |example|
    with_modified_env N8N_AGENT_BOT_TRANSPORTS: [binding].to_json, SAFE_FETCH_ALLOW_PRIVATE_NETWORK: 'false' do
      example.run
    end
  end

  before do
    allow(Resolv).to receive(:getaddresses).with('n8n-private.test').and_return(['172.28.8.10'])
  end

  it 'delivers a signed AgentBot request without the global override' do
    request = stub_request(:post, url).with(headers: { 'X-Chatwoot-Signature' => /sha256=/ }).to_return(body: '{}')
    Webhooks::Trigger.execute(url, payload, :agent_bot_webhook, secret: bot.secret, delivery_id: SecureRandom.uuid)
    expect(request).to have_been_requested.once
    expect(SafeFetch.allow_private_network?).to be(false)
  end

  it 'pins the validated address and disables environment proxies' do
    stub_request(:post, url).to_return(body: '{}')
    pinned_options = hash_including(ipaddr: '172.28.8.10', proxy_from_env: false)
    expect(Net::HTTP).to receive(:start).with('n8n-private.test', 5678, pinned_options).and_call_original
    transport.fetch(url, method: :post, validate_content_type: false) { nil }
  end

  it 'does not perform a second DNS lookup after validating the destination' do
    stub_request(:post, url).to_return(body: '{}')
    expect(Resolv).to receive(:getaddresses).with('n8n-private.test').once.and_return(['172.28.8.10'])
    transport.fetch(url, method: :post, validate_content_type: false) { nil }
  end

  it 'preserves bounded AgentBot retries for transport timeouts' do
    stub_request(:post, url).to_timeout
    expect { Webhooks::Trigger.execute(url, payload, :agent_bot_webhook, secret: bot.secret) }.to raise_error do |error|
      expect(error.class.name).to eq('Webhooks::Trigger::RetryableError')
    end
  end

  it 'leaves unrelated SafeFetch requests blocked even for the configured URL' do
    expect { SafeFetch.fetch(url, method: :post) { nil } }.to raise_error do |error|
      expect(error.class.name).to eq('SafeFetch::UnsafeUrlError')
    end
  end

  it 'does not grant account webhooks the AgentBot exception' do
    expect(SafeFetch).to receive(:fetch).and_call_original
    expect(described_class).not_to receive(:for)
    delivery = Webhooks::Trigger.new(url, payload, :account_webhook, secret: bot.secret)
    expect(delivery).to receive(:handle_failure)
    delivery.execute
  end

  it 'rejects a foreign account payload' do
    expect(described_class.for(url: url, payload: { account: { id: account.id + 1 } }, secret: bot.secret)).to be_nil
  end

  it 'rejects missing and wrong bot secrets' do
    expect(described_class.for(url: url, payload: payload, secret: nil)).to be_nil
    expect(described_class.for(url: url, payload: payload, secret: 'wrong')).to be_nil
  end

  it 'rejects an old secret after rotation' do
    original_secret = bot.secret
    bot.reset_secret!
    expect(described_class.for(url: url, payload: payload, secret: original_secret)).to be_nil
  end

  it 'requires POST and the original bound URL' do
    expect { transport.fetch(url, method: :get) { nil } }.to raise_error do |error|
      expect(error.class.name).to eq('SafeFetch::UnsupportedMethodError')
    end
    expect { transport.fetch('http://169.254.169.254/', method: :post) { nil } }.to raise_error do |error|
      expect(error.class.name).to eq('SafeFetch::UnsafeUrlError')
    end
  end

  it 'does not trust another bot owned by the same tenant' do
    other = create(:agent_bot, account: account, outgoing_url: url)
    expect(described_class.for(url: url, payload: payload, secret: other.secret)).to be_nil
  end

  it 'fails closed after the configured bot changes its outgoing URL' do
    bot.update!(outgoing_url: 'http://another-internal.test/webhook/account-one')
    expect(transport).to be_nil
  end

  it 'does not select the exception for other URLs, ports or paths' do
    ['http://n8n-private.test:6379/webhook/account-one', 'http://other.test:5678/webhook/account-one',
     'http://n8n-private.test:5678/rest/credentials', 'http://169.254.169.254/latest/meta-data/'].each do |other|
      expect(described_class.for(url: other, payload: payload, secret: bot.secret)).to be_nil
    end
  end

  it 'keeps public destinations on the ordinary SafeFetch path' do
    public_url = 'https://public.test/webhook/account-one'
    allow(Resolv).to receive(:getaddresses).with('public.test').and_return(['8.8.8.8'])
    request = stub_request(:post, public_url).to_return(body: '{}')
    expect(described_class.for(url: public_url, payload: payload, secret: bot.secret)).to be_nil
    Webhooks::Trigger.execute(public_url, payload, :agent_bot_webhook, secret: bot.secret)
    expect(request).to have_been_requested.once
  end

  it 'does not grant the exception through a public redirect' do
    public_url = 'https://public.test/webhook/account-one'
    allow(Resolv).to receive(:getaddresses).with('public.test').and_return(['8.8.8.8'])
    stub_request(:post, public_url).to_return(status: 302, headers: { Location: url })
    delivery = Webhooks::Trigger.new(public_url, payload, :agent_bot_webhook, secret: bot.secret)
    expect(delivery).to receive(:handle_failure)
    delivery.execute
    expect(a_request(:post, url)).not_to have_been_made
  end

  [[], ['127.0.0.1'], ['169.254.169.254'], ['8.8.8.8'], ['172.28.8.11'], ['172.28.8.10', '8.8.8.8'], ['::ffff:172.28.8.10']].each do |addresses|
    it "rejects unresolved, mixed or unpinned DNS answers #{addresses.inspect}" do
      allow(Resolv).to receive(:getaddresses).with('n8n-private.test').and_return(addresses)
      expect { transport.fetch(url, method: :post, validate_content_type: false) { nil } }.to raise_error do |error|
        expect(error.class.name).to eq('SafeFetch::UnsafeUrlError')
      end
    end
  end

  it 'supports exact private IPv6 pins without admitting IPv4-mapped bypasses' do
    config = binding.merge(ip_addresses: ['fd00::10'])
    with_modified_env N8N_AGENT_BOT_TRANSPORTS: [config].to_json do
      allow(Resolv).to receive(:getaddresses).with('n8n-private.test').and_return(['fd00::10'])
      stub_request(:post, url).to_return(body: '{}')
      expect { transport.fetch(url, method: :post, validate_content_type: false) { nil } }.not_to raise_error
    end
  end

  [301, 302, 307, 308].each do |status|
    it "rejects #{status} redirects before contacting any second destination" do
      stub_request(:post, url).to_return(status: status, headers: { Location: '/rest/credentials' })
      expect { transport.fetch(url, method: :post, validate_content_type: false) { nil } }.to raise_error do |error|
        expect(error.class.name).to eq('SafeFetch::UnsafeUrlError')
      end
      expect(a_request(:post, 'http://n8n-private.test:5678/rest/credentials')).not_to have_been_made
    end
  end

  ['127.0.0.1', '169.254.169.254', 'fd00:ec2::254', 'fd00::10%eth0', '8.8.8.8', '172.28.8.0/24', '::ffff:172.28.8.10'].each do |address|
    it "rejects invalid or non-private operator pin #{address}" do
      config = binding.merge(ip_addresses: [address])
      with_modified_env N8N_AGENT_BOT_TRANSPORTS: [config].to_json do
        expect { transport }.to raise_error(ArgumentError)
      end
    end
  end

  ['/rest/credentials', '/webhook/../rest', '/webhook/%2e%2e/rest', '/webhook/account-one?target=other',
   '/webhook/account-one#fragment'].each do |path|
    it "rejects unsafe configured route #{path}" do
      config = binding.merge(url: "http://n8n-private.test:5678#{path}")
      with_modified_env N8N_AGENT_BOT_TRANSPORTS: [config].to_json do
        expect { described_class.for(url: config[:url], payload: payload, secret: bot.secret) }.to raise_error(ArgumentError)
      end
    end
  end
end

require 'rails_helper'

describe ChatwootHub do
  describe '.base_url' do
    it 'uses the installation hub URL' do
      expect(described_class::DEFAULT_BASE_URL).to eq('https://volitexai.tech')
      expect(described_class.base_url).to eq('https://volitexai.tech')
    end
  end

  it 'generates a stable installation identifier' do
    installation_identifier = described_class.installation_identifier
    expect(installation_identifier).not_to be_nil
    expect(described_class.installation_identifier).to eq installation_identifier
  end

  context 'when fetching sync_with_hub' do
    before do
      allow(RestClient).to receive(:post)
    end

    it 'does not contact the upstream hub' do
      expect(described_class.sync_with_hub).to eq({})
      expect(RestClient).not_to have_received(:post)
    end

    it 'remains disabled when telemetry is explicitly disabled' do
      with_modified_env DISABLE_TELEMETRY: 'true' do
        expect(described_class.sync_with_hub).to eq({})
        expect(RestClient).not_to have_received(:post)
      end
    end

    it 'does not depend on upstream hub availability' do
      allow(RestClient).to receive(:post).and_raise(RestClient::ServiceUnavailable)
      expect(described_class.sync_with_hub).to eq({})
      expect(RestClient).not_to have_received(:post)
    end
  end

  context 'when registering an instance' do
    it 'does not send owner information to an upstream service' do
      allow(RestClient).to receive(:post)
      expect(described_class.register_instance('test', 'owner', 'owner@example.com')).to eq({})
      expect(RestClient).not_to have_received(:post)
    end
  end

  context 'when sending events' do
    before do
      allow(RestClient).to receive(:post)
    end

    it 'does not transmit instance events' do
      expect(described_class.emit_event('sample_event', { 'sample_data' => 'sample_data' })).to eq({})
      expect(RestClient).not_to have_received(:post)
    end

    it 'remains disabled when telemetry is explicitly disabled' do
      with_modified_env DISABLE_TELEMETRY: 'true' do
        expect(described_class.emit_event('sample_event', { 'sample_data' => 'sample_data' })).to eq({})
        expect(RestClient).not_to have_received(:post)
      end
    end
  end
end

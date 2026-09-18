require 'rails_helper'

RSpec.describe Channel::Whatsapp do
  describe 'provider credential encryption' do
    it 'keeps secrets out of provider_config and reads them back transparently' do
      channel = create(
        :channel_whatsapp,
        provider: 'whatsapp_cloud',
        sync_templates: false,
        validate_provider_config: false
      )
      channel.provider_config = {
        'api_key' => 'waba-access-token',
        'verification_pin' => '123456',
        'webhook_verify_token' => 'webhook-token',
        'phone_number_id' => 'phone-id',
        'business_account_id' => 'waba-id'
      }
      channel.save!(validate: false)

      raw_config = channel.read_attribute(:provider_config)
      expect(raw_config).not_to include('api_key', 'verification_pin', 'webhook_verify_token')
      ciphertext = channel.read_attribute_before_type_cast(:encrypted_provider_config)
      expect(ciphertext).not_to include('waba-access-token', '123456', 'webhook-token')
      expect(channel.provider_config).to include('api_key' => 'waba-access-token', 'verification_pin' => '123456')
    end

    it 'rejects storage of new WhatsApp credentials if encryption keys are absent' do
      allow(Chatwoot).to receive(:encryption_configured?).and_return(false)
      channel = described_class.new(account: create(:account), phone_number: '+919876543210', provider_config: {})

      expect do
        channel.provider_config = { 'api_key' => 'waba-access-token' }
      end.to raise_error(ArgumentError, /encryption keys are required/)
    end
  end
end

class BackfillEncryptedWhatsappProviderConfig < ActiveRecord::Migration[7.0]
  SENSITIVE_KEYS = Channel::Whatsapp::SENSITIVE_PROVIDER_CONFIG_KEYS

  def up
    raise 'Active Record encryption keys must be configured before migrating WhatsApp credentials' unless Chatwoot.encryption_configured?

    Channel::Whatsapp.find_each do |channel|
      raw_config = channel.read_attribute(:provider_config).to_h
      next if raw_config.slice(*SENSITIVE_KEYS).blank?

      channel.provider_config = raw_config
      channel.save!(validate: false)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Do not move encrypted WhatsApp credentials back into plaintext JSONB'
  end
end

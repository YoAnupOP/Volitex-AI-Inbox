class AddEncryptedProviderConfigToChannelWhatsapp < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_whatsapp, :encrypted_provider_config, :text
  end
end

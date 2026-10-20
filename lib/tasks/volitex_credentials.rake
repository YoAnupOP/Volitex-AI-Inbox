namespace :volitex do
  desc 'Move plaintext WhatsApp credentials from provider_config into Active Record encryption'
  task encrypt_whatsapp_provider_configs: :environment do
    abort 'Active Record encryption keys are required before this task can run.' unless Chatwoot.encryption_configured?

    migrated = 0
    Channel::Whatsapp.find_each do |channel|
      raw_config = channel.read_attribute(:provider_config).to_h
      next if raw_config.slice(*Channel::Whatsapp::SENSITIVE_PROVIDER_CONFIG_KEYS).blank?

      channel.provider_config = raw_config
      channel.save!(validate: false)
      migrated += 1
    end

    puts "Encrypted credentials for #{migrated} WhatsApp channel(s)."
  end
end

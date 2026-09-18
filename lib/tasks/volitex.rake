namespace :volitex do
  desc 'Create the dedicated least-privilege n8n AgentBot for an account'
  task :create_n8n_agent_bot, [:account_id, :outgoing_url] => :environment do |_task, args|
    account = Account.find(args[:account_id])
    abort 'Usage: rails volitex:create_n8n_agent_bot[ACCOUNT_ID,https://n8n.example/webhook/volitex-inbox]' if args[:outgoing_url].blank?

    bot = account.agent_bots.create!(
      name: 'Volitex n8n Automation',
      description: 'Dedicated machine identity for the Volitex n8n control plane',
      outgoing_url: args[:outgoing_url],
      bot_config: { 'volitex_control_plane' => 'n8n' }
    )

    puts "AgentBot ID: #{bot.id}"
    puts 'Copy its API token and webhook signing secret from the authenticated dashboard directly into n8n credentials.'
    puts 'Do not print, commit, or put either credential in a shell command.'
    puts 'Assign this AgentBot to each automation inbox in Settings > Inboxes before enabling AI mode.'
  end

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

  desc "Create a new account with an admin user and all default features enabled"
  task :create_account, [:account_name, :email, :password] => :environment do |_t, args|
    account_name = args[:account_name] || "New Account"
    email = args[:email]
    password = args[:password]

    if email.blank? || password.blank?
      puts "Usage: rails volitex:create_account[\"Account Name\",email@example.com,yourpassword]"
      next
    end

    account = Account.create!(name: account_name)

    user = User.create!(
      name: account_name,
      email: email,
      password: password,
      password_confirmation: password
    )
    user.confirm

    AccountUser.create!(account: account, user: user, role: :administrator)

    features = YAML.load_file(Rails.root.join('config/features.yml'))
    features.each do |f|
      account.enable_features(f['name']) if f['enabled']
    end
    account.save!

    puts "✅ Account '#{account_name}' created (ID: #{account.id})"
    puts "✅ Admin user: #{email}"
    puts "✅ Features enabled: #{account.feature_flags}"
  end
end

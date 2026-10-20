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
end

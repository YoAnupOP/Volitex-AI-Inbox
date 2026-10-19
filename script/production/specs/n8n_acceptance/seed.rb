# Synthetic disposable database only. Secrets go to the caller's protected pipe,
# never to a workflow export, test report or operator console.
raise 'Disposable acceptance database required' unless ENV.fetch('POSTGRES_DATABASE') == 'n8n_acceptance'

account = Account.create!(name: 'Synthetic n8n acceptance')
user = User.create!(name: 'Synthetic operator', email: 'operator@example.invalid', password: "S!1#{SecureRandom.hex(24)}", confirmed_at: Time.current)
AccountUser.create!(account: account, user: user, role: :administrator)
channel = Channel::Whatsapp.create!(account: account, phone_number: '+15550001000', provider: 'whatsapp_cloud',
                                    provider_config: { api_key: 'synthetic-only', phone_number_id: 'synthetic-phone',
                                                       business_account_id: 'synthetic-waba', source: 'embedded_signup' })
inbox = Inbox.create!(account: account, channel: channel, name: 'Synthetic WhatsApp')
bot = AgentBot.create!(account: account, name: 'Synthetic n8n', outgoing_url: 'http://probe-n8n:5678/webhook/volitex-staging-account-1',
                       bot_config: { 'volitex_control_plane' => 'n8n' })
AgentBotInbox.create!(account: account, inbox: inbox, agent_bot: bot, status: :active)
contact = Contact.create!(account: account, name: 'Synthetic recipient', phone_number: '+15550002000')
contact_inbox = ContactInbox.create!(contact: contact, inbox: inbox, source_id: '15550002000')
conversation = Conversation.create!(account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox, status: :pending)
Conversations::AutomationOwnershipService.new(conversation: conversation, actor: user).enable_n8n!
fixture = { account_id: account.id, inbox_id: inbox.id, bot_id: bot.id, conversation_id: conversation.id,
            user_id: user.id, api_token: bot.access_token.token, signing_secret: bot.secret }
puts "SYNTHETIC_FIXTURE=#{fixture.to_json}"

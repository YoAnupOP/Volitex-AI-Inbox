require 'rails_helper'

RSpec.describe 'Quick Menu sending API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                              sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:menu) do
    create(:quick_menu, account: account, items: [{ title: 'Billing' }, { title: 'Technical help' }])
  end
  let(:path) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/send_quick_menu" }

  before do
    create(:inbox_member, user: agent, inbox: inbox)
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)
  end

  it 'builds an outgoing input_select through the normal message path with stable IDs and exact titles' do
    post path, params: { quick_menu_id: menu.id }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include('content' => menu.body, 'content_type' => 'input_select')
    expect(response.parsed_body.dig('content_attributes', 'items')).to eq([
                                                                            { 'title' => 'Billing', 'value' => "qm#{menu.id}_1" },
                                                                            { 'title' => 'Technical help', 'value' => "qm#{menu.id}_2" }
                                                                          ])
    expect(conversation.messages.last).to have_attributes(message_type: 'outgoing', sender: agent)
  end

  it 'preserves list rows and generates a unique internal value for every row' do
    titles = ['Billing', 'Technical help', 'Account access', 'Other support']
    menu.update!(items: titles.map { |title| { title: title } })

    post path, params: { quick_menu_id: menu.id }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig('content_attributes', 'items')).to eq(
      titles.each_with_index.map { |title, index| { 'title' => title, 'value' => "qm#{menu.id}_#{index + 1}" } }
    )
  end

  it 'rejects menus and conversations from other accounts without exposing them' do
    other_menu = create(:quick_menu, account: create(:account))
    post path, params: { quick_menu_id: other_menu.id }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end

  it 'rejects closed windows and non-Cloud WhatsApp inboxes' do
    conversation.messages.incoming.each { |message| message.update!(created_at: 25.hours.ago) }
    post path, params: { quick_menu_id: menu.id }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('window_closed')

    other_channel = create(:channel_whatsapp, account: account, provider: 'default', sync_templates: false,
                                              validate_provider_config: false)
    other_conversation = create(:conversation, account: account, inbox: other_channel.inbox)
    create(:inbox_member, user: agent, inbox: other_channel.inbox)
    create(:message, account: account, inbox: other_channel.inbox, conversation: other_conversation,
                     message_type: :incoming)
    post "/api/v1/accounts/#{account.id}/conversations/#{other_conversation.display_id}/send_quick_menu",
         params: { quick_menu_id: menu.id }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('unsupported_inbox')
  end

  it 'rejects a cross-account conversation and an agent without inbox access' do
    other_conversation = create(:conversation, account: create(:account))
    # Display IDs are account-local: use an ID absent from the authenticated account.
    absent_id = account.conversations.maximum(:display_id) + other_conversation.display_id + 1
    post "/api/v1/accounts/#{account.id}/conversations/#{absent_id}/send_quick_menu",
         params: { quick_menu_id: menu.id }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:not_found)
    post "/api/v1/accounts/#{other_conversation.account_id}/conversations/#{other_conversation.display_id}/send_quick_menu",
         params: { quick_menu_id: menu.id }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)

    inbox.inbox_members.destroy_all
    post path, params: { quick_menu_id: menu.id }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects missing menu IDs and invalid saved menus without creating a message' do
    post path, params: {}, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('invalid_request')
    menu.items = [{ title: 'A' * 21 }]
    menu.save!(validate: false)
    expect do
      post path, params: { quick_menu_id: menu.id }, headers: agent.create_new_auth_token, as: :json
    end.not_to change(conversation.messages.outgoing, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('invalid_menu')
  end

  it 'returns a structured error when the normal message builder rejects the message' do
    rejected_message = Message.new
    rejected_message.errors.add(:content, 'was rejected')
    builder = instance_double(Messages::MessageBuilder)
    allow(Messages::MessageBuilder).to receive(:new).and_return(builder)
    allow(builder).to receive(:perform).and_raise(ActiveRecord::RecordInvalid.new(rejected_message))

    post path, params: { quick_menu_id: menu.id }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('message_rejected')
    expect(conversation.messages.outgoing.count).to eq(0)
  end
end

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
end

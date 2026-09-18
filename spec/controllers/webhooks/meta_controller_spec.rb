require 'rails_helper'

RSpec.describe 'Webhooks::MetaController', type: :request do
  include ActiveJob::TestHelper

  let(:app_secret) { 'test-meta-app-secret' }
  let(:meta_user_id) { 'meta-user-123' }
  let(:account) { create(:account) }
  let(:channel) do
    create(
      :channel_whatsapp,
      account: account,
      provider: 'whatsapp_cloud',
      sync_templates: false,
      validate_provider_config: false,
      provider_config: { 'api_key' => 'waba-token', 'phone_number_id' => 'phone-id', 'business_account_id' => 'waba-id',
                         'source' => 'embedded_signup', 'user_id' => meta_user_id }
    )
  end
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, :with_email, account: account, phone_number: '+919876543210') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('META_APP_SECRET', nil).and_return(app_secret)
    teardown_service = instance_double(Whatsapp::WebhookTeardownService, perform: true)
    allow(Whatsapp::WebhookTeardownService).to receive(:new).and_return(teardown_service)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  def signed_request_for(user_id)
    payload = Base64.urlsafe_encode64({ user_id: user_id }.to_json, padding: false)
    signature = OpenSSL::HMAC.digest('sha256', app_secret, payload)
    "#{Base64.urlsafe_encode64(signature, padding: false)}.#{payload}"
  end

  it 'processes a signed callback, erases channel data, and exposes completion status' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation, sender: contact)

    post '/webhooks/meta/data_deletion', params: { signed_request: signed_request_for(meta_user_id) }

    expect(response).to have_http_status(:ok)
    confirmation_code = response.parsed_body.fetch('confirmation_code')
    expect(response.parsed_body.fetch('url')).to end_with("/data-deletion/#{confirmation_code}")
    expect(MetaDataDeletionRequest.find_by!(confirmation_code: confirmation_code).status).to eq('pending')

    perform_enqueued_jobs

    request = MetaDataDeletionRequest.find_by!(confirmation_code: confirmation_code)
    expect(request.status).to eq('completed')
    expect(Message.find_by(id: message.id)).to be_nil
    expect(Inbox.find_by(id: inbox.id)).to be_nil
    expect(contact.reload.phone_number).to be_nil
    expect(contact.email).to be_nil

    get "/data-deletion/#{confirmation_code}"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('confirmation_code' => confirmation_code, 'status' => 'completed')
  end

  it 'rejects an invalid signed callback' do
    post '/webhooks/meta/data_deletion', params: { signed_request: 'invalid' }

    expect(response).to have_http_status(:bad_request)
    expect(MetaDataDeletionRequest.count).to eq(0)
  end
end

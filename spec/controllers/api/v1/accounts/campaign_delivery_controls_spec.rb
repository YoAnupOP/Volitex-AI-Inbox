require 'rails_helper'

RSpec.describe 'Campaign delivery controls', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) { create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:campaign) { create(:campaign, account: account, inbox: channel.inbox, campaign_status: :processing, audience_snapshotted_at: Time.current) }
  let(:contact) { create(:contact, :with_phone_number, account: account) }
  let!(:recipient) { campaign.campaign_recipients.create!(contact: contact, phone_number: contact.phone_number) }
  let(:path) { "/api/v1/accounts/#{account.id}/campaigns/#{campaign.display_id}" }

  it 'allows administrators to pause, resume and cancel without re-creating recipients' do
    post "#{path}/pause", headers: admin.create_new_auth_token
    expect(response).to have_http_status(:ok)
    expect(campaign.reload).to be_paused
    post "#{path}/resume", headers: admin.create_new_auth_token
    expect(response).to have_http_status(:ok)
    expect(campaign.reload).to be_processing
    post "#{path}/cancel", headers: admin.create_new_auth_token
    expect(response).to have_http_status(:ok)
    expect(campaign.reload).to be_cancelled
    expect(recipient.reload.state).to eq('cancelled')
  end

  it 'rejects agent mutations' do
    post "#{path}/pause", headers: agent.create_new_auth_token
    expect(response).to have_http_status(:unauthorized)
    expect(campaign.reload).to be_processing
  end

  it 'rejects unauthenticated controls' do
    post "#{path}/pause"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'does not expose or mutate another account campaign' do
    foreign = create(:campaign)
    foreign.update!(display_id: campaign.display_id + 100)
    post "/api/v1/accounts/#{account.id}/campaigns/#{foreign.display_id}/pause", headers: admin.create_new_auth_token
    expect(response).to have_http_status(:not_found)
    expect(foreign.reload).to be_active
  end

  it 'returns tenant-scoped cursor-paginated recipient outcomes' do
    get "#{path}/recipients", headers: admin.create_new_auth_token
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.pluck('id')).to eq([recipient.id])
    get "#{path}/recipients?after_id=#{recipient.id}", headers: admin.create_new_auth_token
    expect(response.parsed_body).to eq([])
  end

  it 'does not delete a snapshotted delivery history' do
    delete path, headers: admin.create_new_auth_token
    expect(response).to have_http_status(:unprocessable_entity)
    expect(campaign.reload.campaign_recipients.count).to eq(1)
  end

  it 'rejects using another account URL with the current administrator credentials' do
    foreign = create(:campaign)
    post "/api/v1/accounts/#{foreign.account_id}/campaigns/#{foreign.display_id}/pause", headers: admin.create_new_auth_token
    expect(response).to have_http_status(:unauthorized)
    expect(foreign.reload).to be_active
  end

  it 'does not reset legacy processing campaigns into a resendable state' do
    legacy = create(:campaign, account: account, inbox: channel.inbox, campaign_status: :processing)
    post "/api/v1/accounts/#{account.id}/campaigns/#{legacy.display_id}/pause", headers: admin.create_new_auth_token
    expect(response).to have_http_status(:unprocessable_entity)
    expect(legacy.reload).to be_processing
  end

  it 'cancels pending recipients while preserving the in-flight outcome and accurate response counts' do
    recipient.update!(state: 'sending', attempts: 1)
    other_contact = create(:contact, :with_phone_number, account: account)
    campaign.campaign_recipients.create!(contact: other_contact, phone_number: other_contact.phone_number)
    post "#{path}/cancel", headers: admin.create_new_auth_token
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['recipient_counts']).to eq('sending' => 1, 'cancelled' => 1)
    expect(recipient.reload.state).to eq('sending')
  end
end

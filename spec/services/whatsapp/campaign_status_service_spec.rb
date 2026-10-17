require 'rails_helper'

describe Whatsapp::CampaignStatusService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:campaign) { create(:campaign, account: account, inbox: channel.inbox) }
  let(:contact) { create(:contact, :with_phone_number, account: account) }
  let(:recipient) { campaign.campaign_recipients.create!(contact: contact, phone_number: contact.phone_number, state: 'sending', attempts: 1) }

  it 'reconciles an early provider callback before the HTTP result is persisted' do
    described_class.new(inbox: channel.inbox).perform([{ id: 'wamid.early', status: 'delivered',
                                                         biz_opaque_callback_data: "campaign_recipient:#{recipient.id}" }])
    expect(recipient.reload.state).to eq('delivered')
    expect(recipient.provider_message_id).to eq('wamid.early')
  end

  it 'does not reconcile a foreign inbox recipient even when its ID is known' do
    foreign = create(:inbox)
    described_class.new(inbox: foreign).perform([{ id: 'wamid.foreign', status: 'read',
                                                   biz_opaque_callback_data: "campaign_recipient:#{recipient.id}" }])
    expect(recipient.reload.state).to eq('sending')
    expect(recipient.provider_message_id).to be_nil
  end

  it 'handles all statuses in a batch and preserves read over duplicate older delivery' do
    recipient.update!(provider_message_id: 'wamid.batch')
    described_class.new(inbox: channel.inbox).perform(%w[read sent delivered].map { |status| { id: 'wamid.batch', status: status } })
    expect(recipient.reload.state).to eq('read')
  end

  it 'records a failed outcome after sent without undoing a confirmed delivery' do
    recipient.update!(state: 'sent', provider_message_id: 'wamid.failure')
    service = described_class.new(inbox: channel.inbox)
    service.perform([{ id: 'wamid.failure', status: 'failed', errors: [{ code: 131_026 }] }])
    expect(recipient.reload.state).to eq('failed')
    expect(recipient.error_code).to eq('131026')
    service.perform([{ id: 'wamid.failure', status: 'delivered' }])
    service.perform([{ id: 'wamid.failure', status: 'failed' }])
    expect(recipient.reload.state).to eq('delivered')
  end
end

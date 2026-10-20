require 'rails_helper'

describe Whatsapp::OneoffCampaignService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:label) { create(:label, account: account) }
  let(:params) { { 'name' => 'hello', 'language' => 'en', 'processed_params' => { 'body' => {} } } }
  let(:campaign) { create(:campaign, account: account, inbox: channel.inbox, audience: [{ type: 'Label', id: label.id }], template_params: params) }
  let!(:contact) { create(:contact, :with_phone_number, account: account).tap { |record| record.update_labels([label.title]) } }

  before do
    account.enable_features!(:whatsapp_campaign)
    channel.update!(message_templates: [{ name: 'hello', language: 'en', status: 'APPROVED', category: 'MARKETING' }])
  end

  it 'snapshots account recipients without sending and enqueues dispatch' do
    expect { campaign.trigger! }.to have_enqueued_job(Campaigns::DispatchJob)
    expect(campaign.reload).to be_processing
    expect(campaign.campaign_recipients.pluck(:contact_id)).to eq([contact.id])
    expect(campaign.audience_snapshotted_at).to be_present
  end

  it 'does not duplicate snapshot or dispatch chain' do
    2.times { campaign.trigger! }
    expect(campaign.campaign_recipients.count).to eq(1)
    expect(enqueued_jobs.count { |job| job[:job] == Campaigns::DispatchJob }).to eq(1)
  end

  it 'does not select foreign contacts' do
    foreign = create(:contact, :with_phone_number)
    foreign.update_labels([label.title])
    campaign.trigger!
    expect(campaign.campaign_recipients.pluck(:contact_id)).to eq([contact.id])
  end

  it 'does not start with disabled feature' do
    account.disable_features!(:whatsapp_campaign)
    campaign.trigger!
    expect(campaign.reload).to be_active
    expect(campaign.campaign_recipients).to be_empty
  end

  it 'does not start disabled campaigns' do
    campaign.update!(enabled: false)
    campaign.trigger!
    expect(campaign.reload).to be_active
    expect(campaign.campaign_recipients).to be_empty
  end

  it 'rejects unapproved templates atomically' do
    channel.update!(message_templates: [])
    campaign.trigger!
    expect(campaign.reload).to be_failed
    expect(campaign.delivery_error).to eq('invalid_template_or_audience')
    expect(campaign.campaign_recipients).to be_empty
  end

  it 'freezes delivery definition after snapshot' do
    campaign.trigger!
    expect(campaign.update(template_params: { name: 'other' })).to be false
  end

  it 'suppresses recipients without recorded consent in the snapshot' do
    campaign.trigger!
    expect(campaign.campaign_recipients.first.state).to eq('suppressed')
  end

  it 'rejects foreign audience labels rather than silently mixing accounts' do
    campaign.update!(audience: [{ type: 'Label', id: create(:label).id }])
    campaign.trigger!
    expect(campaign.reload).to be_failed
    expect(campaign.campaign_recipients).to be_empty
  end
end

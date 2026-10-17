require 'rails_helper'

describe Whatsapp::CampaignDispatchService do
  include ActiveSupport::Testing::TimeHelpers
  let(:account) { create(:account) }
  let(:channel) { create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:campaign) do
    create(:campaign, account: account, inbox: channel.inbox, campaign_status: :processing, audience_snapshotted_at: Time.current,
                      template_params: { 'name' => 'hello', 'language' => 'en', 'processed_params' => { 'body' => {} } })
  end
  let(:contact) do
    create(:contact, :with_phone_number, account: account,
                                         custom_attributes: { whatsapp_marketing_consent: consent })
  end
  let(:consent) { { status: 'granted', inbox_id: channel.inbox.id, source: 'test form', recorded_at: 1.day.ago.iso8601 } }
  let!(:recipient) { campaign.campaign_recipients.create!(contact: contact, phone_number: contact.phone_number) }
  let(:url) { %r{graph.facebook.com/.*/messages} }

  before do
    account.enable_features!(:whatsapp_campaign)
    channel.update!(message_templates: [{ name: 'hello', language: 'en', status: 'APPROVED', category: 'MARKETING' }])
  end

  it 'records acceptance without a second send' do
    request = stub_request(:post, url).to_return(status: 200, body: { messages: [{ id: 'wamid.test' }] }.to_json,
                                                 headers: { 'Content-Type' => 'application/json' })
    2.times { described_class.new(campaign: campaign).perform }
    expect(recipient.reload.state).to eq('accepted')
    expect(recipient.provider_message_id).to eq('wamid.test')
    expect(request).to have_been_requested.once
    expect(campaign.reload).to be_completed
  end

  it 'does not resend ambiguous timeouts' do
    request = stub_request(:post, url).to_raise(Net::ReadTimeout)
    2.times { described_class.new(campaign: campaign).perform }
    expect(recipient.reload.state).to eq('unknown')
    expect(request).to have_been_requested.once
    expect(campaign.reload).to be_completed_with_errors
  end

  it 'marks an abandoned send claim unknown' do
    recipient.update!(state: 'sending', attempts: 1, claimed_at: 3.minutes.ago)
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('unknown')
    expect(WebMock).not_to have_requested(:post, url)
  end

  it 'bounds rate-limit retries and honors backoff' do
    request = stub_request(:post, url).to_return(status: 429, body: '{}', headers: { 'Content-Type' => 'application/json', 'Retry-After' => '60' })
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('retryable')
    expect(recipient.next_attempt_at).to be >= 59.seconds.from_now
    described_class.new(campaign: campaign).perform
    expect(request).to have_been_requested.once
    travel 61.seconds
    described_class.new(campaign: campaign).perform
    travel 121.seconds
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('failed')
    expect(recipient.attempts).to eq(3)
    expect(request).to have_been_requested.times(3)
  end

  it 'does not blindly retry server errors' do
    stub_request(:post, url).to_return(status: 503, body: '{}', headers: { 'Content-Type' => 'application/json' })
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('unknown')
  end

  it 'suppresses blocked contacts at send time' do
    contact.update!(blocked: true)
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('suppressed')
    expect(WebMock).not_to have_requested(:post, url)
  end

  it 'suppresses revoked consent' do
    contact.update!(custom_attributes: {})
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('suppressed')
  end

  it 'does not send paused campaigns' do
    campaign.update!(campaign_status: :paused)
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('pending')
  end

  it 'paces jobs sharing an inbox' do
    CampaignDispatchSlot.create!(inbox: channel.inbox, available_at: 1.minute.from_now)
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('pending')
  end

  it 'reconciles duplicates and out of order statuses' do
    recipient.update!(state: 'accepted', provider_message_id: 'wamid.test')
    %w[delivered read sent failed read].each { |status| recipient.reconcile!(status: status) }
    expect(recipient.reload.state).to eq('read')
  end

  it 'rejects cross tenant contacts' do
    expect(campaign.campaign_recipients.new(contact: create(:contact), phone_number: '+15550000000')).not_to be_valid
  end

  it 'does not send when the feature is disabled after snapshot' do
    account.disable_features!(:whatsapp_campaign)
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('pending')
    expect(WebMock).not_to have_requested(:post, url)
  end

  it 'rejects a changed provider without making a request' do
    channel.update!(provider: 'default')
    described_class.new(campaign: campaign).perform
    expect(campaign.reload).to be_paused
    expect(WebMock).not_to have_requested(:post, url)
  end

  it 'does not use consent from another inbox' do
    contact.update!(custom_attributes: { whatsapp_marketing_consent: consent.merge(inbox_id: channel.inbox.id + 1) })
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('suppressed')
  end

  it 'does not send to a phone number changed since snapshot' do
    contact.update!(phone_number: '+15559998888')
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('suppressed')
  end

  it 'retries a connection failure before the request was sent' do
    stub_request(:post, url).to_raise(Net::OpenTimeout)
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('retryable')
  end

  it 'recognizes an explicit Meta throughput rejection returned as HTTP 400' do
    stub_request(:post, url).to_return(status: 400, body: { error: { code: 130_429 } }.to_json,
                                       headers: { 'Content-Type' => 'application/json' })
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('retryable')
    expect(recipient.error_code).to eq('meta_130429')
  end

  it 'preserves an early read callback and the consent evidence' do
    stub_request(:post, url).to_return do
      Whatsapp::CampaignStatusService.new(inbox: channel.inbox).perform(
        [{ id: 'wamid.early', status: 'read', biz_opaque_callback_data: "campaign_recipient:#{recipient.id}" }]
      )
      { status: 200, body: { messages: [{ id: 'wamid.early' }] }.to_json, headers: { 'Content-Type' => 'application/json' } }
    end
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.state).to eq('read')
    expect(recipient.consent_snapshot['source']).to eq('test form')
  end

  it 'honors an HTTP-date Retry-After' do
    stub_request(:post, url).to_return(status: 429, body: '{}',
                                       headers: { 'Content-Type' => 'application/json', 'Retry-After' => 10.minutes.from_now.httpdate })
    described_class.new(campaign: campaign).perform
    expect(recipient.reload.next_attempt_at).to be >= 599.seconds.from_now
  end

  it 'keeps reconciliation valid when deleted contacts have null foreign keys' do
    recipient.update!(contact: nil, state: 'accepted')
    other = campaign.campaign_recipients.create!(phone_number: '+15550007777', state: 'accepted')
    recipient.reconcile!(status: 'read')
    other.reconcile!(status: 'read')
    expect([recipient.reload.state, other.reload.state]).to eq(%w[read read])
  end

  it 'redacts deleted contact data without losing the delivery outcome' do
    recipient.update!(state: 'accepted', consent_snapshot: consent)
    contact.destroy!
    expect(recipient.reload.contact_id).to be_nil
    expect(recipient.phone_number).to eq('')
    expect(recipient.consent_snapshot).to eq({})
    recipient.reconcile!(status: 'delivered')
    expect(recipient.reload.state).to eq('delivered')
  end
end

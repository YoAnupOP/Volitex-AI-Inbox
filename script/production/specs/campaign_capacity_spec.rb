require 'rails_helper'

# Run explicitly against an empty disposable test database. No provider traffic.
RSpec.describe 'Synthetic WhatsApp campaign capacity', type: :job do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  [1_000, 2_000, 5_000, 10_000].each do |size|
    it "processes #{size} synthetic recipients through the existing campaign job" do
      freeze_time
      account = create(:account)
      account.enable_features!(:whatsapp_campaign)
      channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                          validate_provider_config: false, sync_templates: false)
      channel.update!(message_templates: [{ name: 'synthetic_probe', language: 'en', status: 'APPROVED', category: 'MARKETING' }])
      label = create(:label, account: account)
      template = { 'name' => 'synthetic_probe', 'language' => 'en', 'processed_params' => {} }
      campaign = create(:campaign, account: account, inbox: channel.inbox,
                                   audience: [{ type: 'Label', id: label.id }], template_params: template)
      now = Time.current
      # Bulk synthetic fixtures measure the sender, not per-record onboarding callbacks.
      # rubocop:disable Rails/SkipsModelValidations
      contacts = Contact.insert_all!(Array.new(size) do |index|
        { account_id: account.id, name: 'Synthetic recipient', phone_number: "+1555#{index.to_s.rjust(7, '0')}",
          custom_attributes: { whatsapp_marketing_consent: { status: 'granted', source: 'synthetic test', inbox_id: channel.inbox.id, recorded_at: now.iso8601 } },
          created_at: now, updated_at: now }
      end, returning: %w[id])
      tag = ActsAsTaggableOn::Tag.find_or_create_by!(name: label.title)
      ActsAsTaggableOn::Tagging.insert_all!(contacts.rows.map do |row|
        { tag_id: tag.id, taggable_type: 'Contact', taggable_id: row.first, context: 'labels', created_at: now }
      end)
      # rubocop:enable Rails/SkipsModelValidations
      deliveries = []
      probe_latencies = []
      dispatch_latencies = []
      # Actual processor/provider serialization; only HTTP transport is mocked.
      stub_request(:post, %r{graph.facebook.com/.*/messages}).to_return do |request|
        body = JSON.parse(request.body)
        deliveries << body.fetch('to')
        if (deliveries.length % 100).zero?
          probe_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          expect(Account.find(account.id).id).to eq(account.id)
          probe_latencies << (Process.clock_gettime(Process::CLOCK_MONOTONIC) - probe_start)
        end
        { status: 200, body: { messages: [{ id: "mock.#{body.fetch('biz_opaque_callback_data')}" }] }.to_json,
          headers: { 'Content-Type' => 'application/json' } }
      end
      enqueue_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      expect { Campaigns::TriggerOneoffCampaignJob.perform_later(campaign) }.to have_enqueued_job(Campaigns::TriggerOneoffCampaignJob)
      enqueue_seconds = Process.clock_gettime(Process::CLOCK_MONOTONIC) - enqueue_start
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      cpu_started = Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID)
      perform_enqueued_jobs(only: Campaigns::TriggerOneoffCampaignJob)
      expect(campaign.reload.campaign_recipients.count).to eq(size)
      snapshot_seconds = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      # Accelerate only the test clock. Production pacing remains one request/sec/inbox.
      size.times do
        dispatch_started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        Whatsapp::CampaignDispatchService.new(campaign: campaign).perform
        dispatch_latencies << (Process.clock_gettime(Process::CLOCK_MONOTONIC) - dispatch_started)
        travel 1.second
      end
      Whatsapp::CampaignDispatchService.new(campaign: campaign).perform
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      cpu_seconds = Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID) - cpu_started
      expect(deliveries.length).to eq(size)
      expect(deliveries.uniq.length).to eq(size)
      expect(campaign.reload).to be_completed
      Campaigns::TriggerOneoffCampaignJob.perform_now(campaign)
      expect(deliveries.length).to eq(size)
      sorted = probe_latencies.sort
      dispatch_sorted = dispatch_latencies.sort
      expect(campaign.campaign_recipients.where(state: 'accepted').count).to eq(size)
      travel_back
      campaign_dispatch_jobs = enqueued_jobs.count { |job| job[:job] == Campaigns::DispatchJob }
      puts({ recipients: size, test_adapter_jobs: enqueued_jobs.size, campaign_dispatch_jobs: campaign_dispatch_jobs,
             adapter: 'ActiveJob test + direct dispatcher, accelerated clock', provider: 'mocked', enqueue_seconds: enqueue_seconds,
             snapshot_seconds: snapshot_seconds, processing_seconds: elapsed, recipients_per_second: size / elapsed, cpu_seconds: cpu_seconds,
             peak_process_rss_kib: File.read('/proc/self/status')[/VmHWM:\s+(\d+)/, 1].to_i,
             account_read_p95_ms: sorted[(sorted.length * 0.95).floor] * 1_000,
             dispatch_p50_ms: dispatch_sorted[(size * 0.50).floor] * 1_000,
             dispatch_p95_ms: dispatch_sorted[(size * 0.95).floor] * 1_000,
             dispatch_p99_ms: dispatch_sorted[(size * 0.99).floor] * 1_000,
             duplicates: deliveries.length - deliveries.uniq.length,
             database_bytes: ActiveRecord::Base.connection.select_value('SELECT pg_database_size(current_database())').to_i }.to_json)
    end
  end
end

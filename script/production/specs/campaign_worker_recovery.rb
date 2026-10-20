# Real PostgreSQL + Redis + Sidekiq crash/replay test, with a loopback-only fake Meta.
# Run only against a disposable test database and an unused Redis logical database.
abort 'RAILS_ENV=test required' unless ENV['RAILS_ENV'] == 'test'
require 'uri'
redis_uri = URI(ENV.fetch('CAMPAIGN_VERIFY_REDIS_URL'))
abort 'Loopback Redis required' unless %w[127.0.0.1 localhost].include?(redis_uri.host)
ENV['REDIS_URL'] = redis_uri.to_s
require_relative 'campaign_worker_boot'
require 'factory_bot_rails'
require 'sidekiq/api'
require 'socket'
require 'tmpdir'
unless ActiveRecord::Base.connection_db_config.database.match?(/\A(?:chatwoot_test|volitex_(?:ui_check|campaign_specs)_\d+)\z/)
  abort 'Disposable test database required'
end
abort 'Redis logical database must be empty' unless Redis.new(url: redis_uri.to_s).dbsize.zero?

scratch = Dir.mktmpdir('volitex-campaign-worker-')
server = TCPServer.new('127.0.0.1', 0)
ENV['WHATSAPP_CLOUD_BASE_URL'] = "http://127.0.0.1:#{server.addr[1]}"
requests = Hash.new(0)
mutex = Mutex.new
slow = true
http = Thread.new do
  loop do
    client = server.accept
    length = 0
    while (line = client.gets) && line != "\r\n"
      length = line.split(':', 2).last.to_i if line.downcase.start_with?('content-length:')
    end
    body = JSON.parse(client.read(length))
    id = body.fetch('biz_opaque_callback_data').split(':').last
    mutex.synchronize { requests[id] += 1 }
    sleep 4 if slow
    payload = { messages: [{ id: "wamid.verification.#{id}" }] }.to_json
    begin
      client.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{payload.bytesize}\r\nConnection: close\r\n\r\n#{payload}")
    rescue Errno::EPIPE, Errno::ECONNRESET
      # The deliberately killed worker cannot receive this response.
    ensure
      client.close
    end
  end
rescue IOError, Errno::EBADF
  nil
end

pids = []
begin
  account = FactoryBot.create(:account)
  account.enable_features!(:whatsapp_campaign)
  channel = FactoryBot.create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', phone_number: "+1999#{Time.now.to_i}#{rand(100)}",
                                                 validate_provider_config: false, sync_templates: false)
  channel.update!(message_templates: [{ name: 'hello', language: 'en', status: 'APPROVED', category: 'MARKETING' }])
  campaign = FactoryBot.create(:campaign, account: account, inbox: channel.inbox, campaign_status: :processing,
                                          audience_snapshotted_at: Time.current,
                                          template_params: { name: 'hello', language: 'en', processed_params: { body: {} } })
  recipients = 3.times.map do
    contact = FactoryBot.create(:contact, :with_phone_number, account: account,
                                                              custom_attributes: { whatsapp_marketing_consent: { status: 'granted', source: 'synthetic test',
                                                                                                                 inbox_id: channel.inbox.id, recorded_at: 1.day.ago.iso8601 } })
    campaign.campaign_recipients.create!(contact: contact, phone_number: contact.phone_number)
  end
  worker = Process.spawn('bundle', 'exec', 'sidekiq', '-r', './script/production/specs/campaign_worker_boot.rb', '-C', 'config/sidekiq_campaigns.yml', '-q', 'campaigns', '-c', '2',
                         out: "#{scratch}/campaign-worker.log", err: [:child, :out])
  pids << worker
  normal = Process.spawn('bundle', 'exec', 'sidekiq', '-r', './script/production/specs/campaign_worker_boot.rb', '-q', 'critical', '-c', '1',
                         out: "#{scratch}/normal-worker.log", err: [:child, :out])
  pids << normal
  deadline = 60.seconds.from_now
  sleep 0.1 until Sidekiq::ProcessSet.new.size >= 2 || Time.current >= deadline
  raise 'Worker startup failed' unless Sidekiq::ProcessSet.new.size >= 2
  raise 'Worker health check failed' unless system('bundle', 'exec', 'ruby', 'script/production/campaign_worker_health.rb')

  campaign.enqueue_dispatch
  original_token = campaign.reload.dispatch_token
  deadline = 20.seconds.from_now
  sleep 0.05 until mutex.synchronize { requests.values.sum.positive? } || Time.current >= deadline
  raise 'Provider was never reached' unless mutex.synchronize { requests.values.sum == 1 }
  raise 'Send intent was not committed' unless recipients.first.reload.state == 'sending'

  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  CampaignVerificationProbeJob.perform_later("#{scratch}/normal-probe")
  sleep 0.05 until File.exist?("#{scratch}/normal-probe") || Process.clock_gettime(Process::CLOCK_MONOTONIC) - started > 5
  normal_latency = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  raise 'Campaign blocked critical queue' unless File.exist?("#{scratch}/normal-probe")

  Process.kill('KILL', worker)
  Process.wait(worker)
  pids.delete(worker)
  slow = false
  recipients.first.update!(claimed_at: 3.minutes.ago)
  campaign.update!(dispatch_scheduled_at: 3.minutes.ago)
  worker = Process.spawn('bundle', 'exec', 'sidekiq', '-r', './script/production/specs/campaign_worker_boot.rb', '-C', 'config/sidekiq_campaigns.yml', '-q', 'campaigns', '-c', '2',
                         out: "#{scratch}/restarted-worker.log", err: [:child, :out])
  pids << worker
  Campaigns::RecoverJob.perform_now
  5.times { Campaigns::DispatchJob.perform_later(campaign, original_token) }
  deadline = 60.seconds.from_now
  sleep 0.1 until campaign.reload.completed_with_errors? || Time.current >= deadline
  raise 'Campaign did not recover' unless campaign.completed_with_errors?
  raise 'Abandoned recipient was resent' unless recipients.first.reload.state == 'unknown'
  raise 'Pending recipients were lost' unless recipients.drop(1).all? { |recipient| recipient.reload.state == 'accepted' }
  raise 'Duplicate provider call' unless mutex.synchronize { requests.values.all? { |count| count == 1 } && requests.size == 3 }

  overlap = FactoryBot.create(:campaign, account: account, inbox: channel.inbox, campaign_status: :processing,
                                         audience_snapshotted_at: Time.current, template_params: campaign.template_params)
  recipients.each { |recipient| overlap.campaign_recipients.create!(contact: recipient.contact, phone_number: recipient.phone_number) }
  overlap.enqueue_dispatch
  overlap_token = overlap.reload.dispatch_token
  5.times { Campaigns::DispatchJob.perform_later(overlap, overlap_token) }
  deadline = 60.seconds.from_now
  sleep 0.1 until overlap.reload.completed? || Time.current >= deadline
  raise 'Overlapping jobs did not finish' unless overlap.completed?
  raise 'Overlapping jobs duplicated a send' unless mutex.synchronize { requests.size == 6 && requests.values.all? { |count| count == 1 } }

  puts JSON.generate(result: 'PASS', recipients: 6, provider_calls: 6, accepted: 5, unknown: 1,
                     duplicate_calls: 0, lost_pending: 0, stale_jobs_replayed: 5, overlapping_jobs: 5, critical_job_latency_seconds: normal_latency.round(3),
                     evidence_directory: scratch, provider: 'loopback fake Meta', redis: 'real', workers: 'real Sidekiq processes')
ensure
  pids.each do |pid|
    Process.kill('TERM', pid)
    Process.wait(pid)
  rescue Errno::ESRCH, Errno::ECHILD
    nil
  end
  server.close
  http.join(5)
end

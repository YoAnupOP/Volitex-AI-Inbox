#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'openssl'
require 'optparse'
require 'uri'

CHANNELS = %w[whatsapp instagram].freeze

options = {
  channel: 'whatsapp',
  concurrency: 10,
  events: 100,
  duplicates: 1,
  timeout: 15,
  secret_env: 'LOAD_TEST_META_APP_SECRET'
}

OptionParser.new do |parser|
  parser.banner = 'Usage: webhook_load_test.rb --base-url URL --tenants ID[,ID,...] [options]'
  parser.on('--base-url URL', 'Staging base URL, for example https://staging.example.com') { |value| options[:base_url] = value }
  parser.on('--channel CHANNEL', CHANNELS, 'whatsapp or instagram') { |value| options[:channel] = value }
  parser.on('--tenants IDS', 'Comma-separated test phone numbers or Instagram account IDs') do |value|
    options[:tenants] = value.split(',').map(&:strip).reject(&:empty?)
  end
  parser.on('--events N', Integer, 'Unique payloads per tenant') { |value| options[:events] = value }
  parser.on('--duplicates N', Integer, 'Additional deliveries of every payload') { |value| options[:duplicates] = value }
  parser.on('--concurrency N', Integer, 'Concurrent HTTP workers') { |value| options[:concurrency] = value }
  parser.on('--timeout SECONDS', Integer, 'HTTP timeout per request') { |value| options[:timeout] = value }
  parser.on('--secret-env NAME', 'Environment variable containing the Meta app secret') { |value| options[:secret_env] = value }
  parser.on('--allow-public-host', 'Explicitly allow a public Volitex hostname; never use for production') { options[:allow_public_host] = true }
  parser.on('-h', '--help', 'Show help') { puts parser; exit }
end.parse!

abort 'Set --base-url' unless options[:base_url]
abort 'Set --tenants with at least one configured staging tenant' if options[:tenants].to_a.empty?
abort '--events must be positive' unless options[:events].positive?
abort '--duplicates must not be negative' if options[:duplicates].negative?
abort '--concurrency must be positive' unless options[:concurrency].positive?

base_uri = URI.parse(options[:base_url])
abort 'Base URL must use http or https' unless %w[http https].include?(base_uri.scheme)
if %w[inbox.volitexai.tech automation.volitexai.tech].include?(base_uri.host) && !options[:allow_public_host]
  abort 'Refusing production host; use an isolated staging host'
end

secret = ENV.fetch(options[:secret_env]) do
  abort "Set #{options[:secret_env]} in the environment; do not pass secrets on the command line"
end

def payload_for(channel, tenant, index)
  user_id = "load-test-user-#{tenant}-#{index}"
  message_id = "load-test-message-#{tenant}-#{index}"

  if channel == 'whatsapp'
    {
      object: 'whatsapp_business_account',
      entry: [{
        id: "load-test-waba-#{tenant}",
        changes: [{
          field: 'messages',
          value: {
            metadata: { display_phone_number: tenant, phone_number_id: tenant },
            contacts: [{ wa_id: user_id, profile: { name: 'Load Test' } }],
            messages: [{ from: user_id, id: message_id, timestamp: Time.now.to_i.to_s, type: 'text', text: { body: "load test #{index}" } }]
          }
        }]
      }]
    }
  else
    {
      object: 'instagram',
      entry: [{
        id: tenant,
        time: Time.now.to_i,
        messaging: [{
          sender: { id: user_id },
          recipient: { id: tenant },
          timestamp: Time.now.to_i,
          message: { mid: message_id, text: "load test #{index}" }
        }]
      }]
    }
  end
end

requests = []
options[:tenants].each do |tenant|
  options[:events].times do |index|
    body = JSON.generate(payload_for(options[:channel], tenant, index))
    delivery_count = options[:duplicates] + 1
    delivery_count.times do |copy|
      requests << { tenant: tenant, index: index, copy: copy, body: body }
    end
  end
end

path_for = lambda do |tenant|
  if options[:channel] == 'whatsapp'
    "/webhooks/whatsapp/#{URI.encode_www_form_component(tenant)}"
  else
    '/webhooks/instagram'
  end
end

queue = Queue.new
requests.each { |request| queue << request }
results = []
mutex = Mutex.new

workers = [options[:concurrency], requests.length].min.times.map do
  Thread.new do
    loop do
      begin
        request = queue.pop(true)
      rescue ThreadError
        break
      end

      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      uri = base_uri.dup
      uri.path = path_for.call(request[:tenant])
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = options[:timeout]
      http.read_timeout = options[:timeout]
      post = Net::HTTP::Post.new(uri.request_uri)
      post['Content-Type'] = 'application/json'
      post['X-Hub-Signature-256'] = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, request[:body])}"
      post.body = request[:body]
      response = http.request(post)
      result = { status: response.code.to_i, latency_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round }
    rescue StandardError => e
      result = { status: "error:#{e.class.name}", latency_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round }
    ensure
      mutex.synchronize { results << result.merge(tenant: request[:tenant], index: request[:index], copy: request[:copy]) } if result
    end
  end
end
workers.each(&:join)

latencies = results.map { |result| result[:latency_ms] }.sort
percentile = lambda do |fraction|
  latencies[[((latencies.length - 1) * fraction).round, 0].max]
end
statuses = results.group_by { |result| result[:status].to_s }.transform_values(&:length)
failures = results.count { |result| result[:status].to_i < 200 || result[:status].to_i >= 300 }

puts JSON.pretty_generate(
  channel: options[:channel],
  tenants: options[:tenants],
  unique_payloads: options[:events] * options[:tenants].length,
  deliveries: requests.length,
  duplicate_deliveries: options[:events] * options[:tenants].length * options[:duplicates],
  concurrency: options[:concurrency],
  statuses: statuses,
  error_rate: (failures.to_f / results.length).round(4),
  latency_ms: { p50: percentile.call(0.50), p95: percentile.call(0.95), p99: percentile.call(0.99), max: latencies.max }
)

exit 1 unless failures.zero?

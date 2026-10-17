# Container health check: verify this host has a recent campaign Sidekiq heartbeat.
require 'json'
require 'socket'
require 'redis'

begin
  options = { url: ENV.fetch('REDIS_URL'), timeout: 2 }
  options[:password] = ENV.fetch('REDIS_PASSWORD', nil) unless ENV['REDIS_PASSWORD'].to_s.empty?
  redis = Redis.new(**options)
  healthy = redis.smembers('processes').any? do |identity|
    info = redis.hget(identity, 'info')
    next false unless info

    process = JSON.parse(info)
    process['hostname'] == Socket.gethostname && Array(process['queues']).include?('campaigns') &&
      redis.hget(identity, 'beat').to_f > Time.now.to_f - 60
  end
  abort 'Campaign worker heartbeat missing' unless healthy
rescue StandardError => e
  warn "Campaign worker heartbeat unavailable (#{e.class.name})"
  exit 1
end

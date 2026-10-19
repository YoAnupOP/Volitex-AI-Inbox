# Container health check: verify this host has a recent heartbeat for the required queue.
require 'json'
require 'socket'
require 'redis'

begin
  queue = ENV.fetch('SIDEKIQ_HEALTH_QUEUE', 'campaigns')
  options = { url: ENV.fetch('REDIS_URL'), timeout: 2 }
  options[:password] = ENV.fetch('REDIS_PASSWORD', nil) unless ENV['REDIS_PASSWORD'].to_s.empty?
  redis = Redis.new(**options)
  healthy = redis.smembers('processes').any? do |identity|
    info = redis.hget(identity, 'info')
    next false unless info

    process = JSON.parse(info)
    process['hostname'] == Socket.gethostname && Array(process['queues']).include?(queue) &&
      redis.hget(identity, 'beat').to_f > Time.now.to_f - 60
  end
  abort 'Required worker heartbeat missing' unless healthy
rescue StandardError => e
  warn "Worker heartbeat unavailable (#{e.class.name})"
  exit 1
end

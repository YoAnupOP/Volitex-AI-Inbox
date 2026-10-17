# Test-only boot file for real Sidekiq processes. Never load this in production.
abort 'Campaign verification requires RAILS_ENV=test' unless ENV['RAILS_ENV'] == 'test'
require_relative '../../../config/environment'
ActiveJob::Base.queue_adapter = :sidekiq

class CampaignVerificationProbeJob < ApplicationJob
  queue_as :critical

  def perform(path)
    File.write(path, Time.current.iso8601)
  end
end

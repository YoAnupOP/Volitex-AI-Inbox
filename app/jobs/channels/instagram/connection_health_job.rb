class Channels::Instagram::ConnectionHealthJob < ApplicationJob
  queue_as :low
  retry_on Instagram::GraphClient::Error, wait: :polynomially_longer, attempts: 4 do |job, error|
    channel = job.arguments.first
    Rails.logger.error("Instagram health retries exhausted account_id=#{channel.account_id} channel_id=#{channel.id} " \
                       "status=#{error.status} code=#{error.provider_code} attempts=4")
    channel.notify_connection_failure
  end

  def perform(channel)
    channel.reload
    if recovering_subscription?(channel)
      channel.subscribe(reauthorize: true)
      return
    end

    token = Instagram::RefreshOauthTokenService.new(channel: channel).refresh!
    return if token.blank?

    channel.subscribe if channel.subscription_verified_at.nil? || channel.subscription_verified_at <= 1.day.ago
  rescue Instagram::GraphClient::Error => e
    raise unless e.authorization_error?
  end

  private

  def recovering_subscription?(channel)
    channel.reauthorization_required? && channel.subscription_verified_at.nil? && channel.expires_at.future?
  end
end

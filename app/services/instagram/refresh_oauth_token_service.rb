class Instagram::RefreshOauthTokenService
  attr_reader :channel

  def initialize(channel:)
    @channel = channel
  end

  def access_token
    return channel[:access_token] if channel.new_record?

    channel.reload
    return refresh! if channel.expires_at <= Time.current
    return if channel.reauthorization_required?

    channel[:access_token]
  end

  # Reload and lock so parallel refreshes/reconnects cannot overwrite newer tokens.
  # Renewal belongs to scheduled jobs, not customer request latency.
  def refresh!
    failure = nil
    token = channel.with_lock do
      current_or_refreshed_token
    rescue Instagram::GraphClient::Error => e
      channel.prompt_reauthorization! if e.authorization_error? && !channel.reauthorization_required?
      failure = e
      nil
    end
    raise failure if failure

    token
  end

  private

  def current_or_refreshed_token
    if channel.expires_at <= Time.current
      channel.prompt_reauthorization! unless channel.reauthorization_required?
      nil
    elsif channel.reauthorization_required?
      nil
    elsif token_eligible_for_refresh?
      refresh_locked_token
    else
      channel[:access_token]
    end
  end

  def token_eligible_for_refresh?
    channel.token_refreshed_at <= 24.hours.ago && channel.expires_at <= 10.days.from_now
  end

  def refresh_locked_token
    data = Instagram::GraphClient.new(channel[:access_token]).request(:get, 'refresh_access_token',
                                                                      params: { grant_type: 'ig_refresh_token' }, versioned: false)
    raise Instagram::GraphClient::Error.new(status: 502) if data['access_token'].blank? || data['expires_in'].to_i <= 0

    channel.update!(access_token: data['access_token'], expires_at: data['expires_in'].to_i.seconds.from_now, token_refreshed_at: Time.current)
    channel[:access_token]
  end
end

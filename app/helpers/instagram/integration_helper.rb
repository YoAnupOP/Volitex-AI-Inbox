module Instagram::IntegrationHelper
  REQUIRED_SCOPES = %w[instagram_business_basic instagram_business_manage_messages instagram_business_manage_comments].freeze
  STATE_LIFETIME = 10.minutes

  class InvalidState < StandardError; end

  def generate_instagram_token(account_id, return_to = nil, user_id:, browser_nonce:, inbox_id: nil)
    raise InvalidState, 'Instagram app configuration is missing' if client_secret.blank?

    payload = { sub: account_id, user_id: user_id, inbox_id: inbox_id, iat: Time.current.to_i,
                exp: STATE_LIFETIME.from_now.to_i, jti: SecureRandom.uuid, return_to: return_to }
    Redis::Alfred.setex("instagram:oauth_state:#{payload[:jti]}", Digest::SHA256.hexdigest(browser_nonce), STATE_LIFETIME.to_i)
    JWT.encode(payload, client_secret, 'HS256')
  end

  def consume_instagram_state!(token, browser_nonce:)
    raise InvalidState, 'Instagram authorization state is missing' if token.blank? || browser_nonce.blank? || client_secret.blank?

    payload = JWT.decode(token, client_secret, true, algorithm: 'HS256', verify_expiration: true,
                                                     required_claims: %w[sub user_id iat exp jti]).first
    key = "instagram:oauth_state:#{payload.fetch('jti')}"
    expected = Digest::SHA256.hexdigest(browser_nonce)
    verify_state_binding!(payload, key, expected)
    raise InvalidState, 'Instagram authorization state was already used' unless Redis::Alfred.delete_if_equals(key, expected) == [1]

    payload
  rescue JWT::DecodeError
    raise InvalidState, 'Instagram authorization state is invalid or expired'
  end

  private

  def verify_state_binding!(payload, key, expected)
    actual = Redis::Alfred.get(key)
    raise InvalidState, 'Instagram authorization state is invalid' unless actual && ActiveSupport::SecurityUtils.secure_compare(actual, expected)

    membership = AccountUser.find_by(account_id: payload['sub'], user_id: payload['user_id'])
    raise InvalidState, 'Instagram administrator access is required' unless membership&.administrator?
  end

  def client_secret
    @client_secret ||= GlobalConfigService.load('INSTAGRAM_APP_SECRET', nil)
  end
end

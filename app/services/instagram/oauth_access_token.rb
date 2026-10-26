class Instagram::OauthAccessToken < OAuth2::AccessToken
  # Meta documents a data-array envelope; older responses use a flat token hash.
  # Keep OAuth2's transport and token handling while normalizing both responses.
  def self.from_hash(client, response)
    payload = response['data'].is_a?(Array) ? response['data'].first : response
    raise Instagram::GraphClient::Error.new(status: 502) unless payload.is_a?(Hash) && payload['access_token'].present?

    super(client, payload)
  end
end

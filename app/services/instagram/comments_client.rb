# Client for comment moderation through the Instagram API with Instagram Login.
#
# This intentionally uses graph.instagram.com, rather than the Facebook Graph
# host used by the legacy Facebook Login integration.
class Instagram::CommentsClient
  GRAPH_HOST = 'https://graph.instagram.com'.freeze
  MEDIA_FIELDS = 'id,caption,media_type,media_product_type,media_url,thumbnail_url,timestamp,permalink'.freeze
  COMMENT_FIELDS = 'id,text,timestamp,username,hidden,like_count,replies{id,text,timestamp,username,hidden}'.freeze
  RATE_LIMIT_ERROR_CODES = [4, 17, 32, 613, 80007].freeze

  class RequestError < StandardError
    attr_reader :status, :retry_after

    def initialize(message, status:, retry_after: nil)
      super(message)
      @status = status
      @retry_after = retry_after
    end
  end

  def initialize(channel)
    @channel = channel
  end

  def media(after: nil)
    get(channel.instagram_id, fields: MEDIA_FIELDS, limit: 50, after: after)
  end

  def comments(media_id, after: nil)
    get(media_id, fields: COMMENT_FIELDS, limit: 100, after: after, edge: 'comments')
  end

  def create_comment(media_id, message)
    post(media_id, message: message, edge: 'comments')
  end

  def reply(comment_id, message)
    post(comment_id, message: message, edge: 'replies')
  end

  def update_visibility(comment_id, hidden:)
    post(comment_id, hide: hidden)
  end

  def delete(comment_id)
    request(:delete, comment_id)
  end

  private

  attr_reader :channel

  def get(object_id, edge: nil, **params)
    request(:get, object_id, edge: edge, params: params)
  end

  def post(object_id, edge: nil, **params)
    request(:post, object_id, edge: edge, params: params)
  end

  def request(method, object_id, edge: nil, params: {})
    ensure_identifier!(object_id)
    token = channel.access_token
    raise RequestError.new('Instagram authorization has expired. Please reconnect this inbox.', status: :unauthorized) if token.blank?

    request_params = params.compact.merge(access_token: token)
    response = HTTParty.public_send(
      method,
      endpoint(object_id, edge),
      request_options(method, request_params)
    )

    return response.parsed_response if response.success?

    raise_error(response)
  rescue HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    raise RequestError.new("Instagram could not be reached: #{e.message}", status: :bad_gateway)
  end

  def endpoint(object_id, edge)
    path = [api_version, object_id, edge].compact.join('/')
    "#{GRAPH_HOST}/#{path}"
  end

  def api_version
    GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')
  end

  def request_options(method, params)
    if method == :get || method == :delete
      { query: params, headers: { 'Accept' => 'application/json' } }
    else
      { body: params, headers: { 'Accept' => 'application/json' } }
    end
  end

  def ensure_identifier!(object_id)
    return if object_id.to_s.match?(/\A\d+\z/)

    raise RequestError.new('The Instagram media or comment identifier is invalid.', status: :unprocessable_entity)
  end

  def raise_error(response)
    body = response.parsed_response
    error = body.is_a?(Hash) ? body['error'] || body[:error] : nil
    code = error&.dig('code') || error&.dig(:code)
    message = error&.dig('message') || error&.dig(:message) || 'Instagram could not complete this request.'
    rate_limited = response.code == 429 || RATE_LIMIT_ERROR_CODES.include?(code.to_i)
    status = rate_limited ? :too_many_requests : response.code

    raise RequestError.new(message, status: status, retry_after: response.headers['retry-after'])
  end
end

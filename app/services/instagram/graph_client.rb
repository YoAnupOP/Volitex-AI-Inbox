class Instagram::GraphClient
  class Error < StandardError
    attr_reader :status, :provider_code

    def initialize(status:, provider_code: nil)
      @status = status.to_i
      @provider_code = provider_code.to_i
      super("Instagram API failure (HTTP #{@status}, code #{@provider_code})")
    end

    def authorization_error?
      status == 401 || [10, 102, 190, 200].include?(provider_code)
    end
  end

  def initialize(access_token)
    @access_token = access_token
  end

  def request(method, path, params: {}, versioned: true)
    version = GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')
    path = "#{version}/#{path}" if versioned
    response = HTTParty.public_send(method, "https://graph.instagram.com/#{path}",
                                    query: params.merge(access_token: @access_token),
                                    open_timeout: 5, timeout: 15)
    data = JSON.parse(response.body)
    raise Error.new(status: 502) unless data.is_a?(Hash)

    code = data['error'].is_a?(Hash) ? data['error']['code'] : nil
    raise Error.new(status: response.code, provider_code: code) if !response.success? || data['error'].present?

    data
  rescue JSON::ParserError
    raise Error.new(status: response.code), cause: nil
  rescue HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, SocketError, EOFError,
         OpenSSL::SSL::SSLError, Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ETIMEDOUT
    raise Error.new(status: 503), cause: nil
  end
end

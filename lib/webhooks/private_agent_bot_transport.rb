require 'ipaddr'

# Operator-owned bindings, never a tenant-provided allowlist. SafeFetch's default
# policy and its global private-network switch are not used for this transport.
class Webhooks::PrivateAgentBotTransport
  def self.for(url:, payload:, secret:)
    bindings = JSON.parse(ENV.fetch('N8N_AGENT_BOT_TRANSPORTS', '[]'))
    raise ArgumentError, 'N8N_AGENT_BOT_TRANSPORTS must be an array' unless bindings.is_a?(Array)

    matches = bindings.select { |binding| binding.fetch('url') == url }
    raise ArgumentError, 'Duplicate private AgentBot URL binding' if matches.size > 1
    return if matches.empty?

    transport = new(matches.first)
    transport if transport.authorized?(payload, secret)
  end

  def initialize(binding)
    @url = binding.fetch('url')
    @uri = URI(@url)
    @account_id = binding.fetch('account_id')
    @agent_bot_id = binding.fetch('agent_bot_id')
    valid_ids = [@account_id, @agent_bot_id].all? { |id| id.is_a?(Integer) && id.positive? }
    raise ArgumentError, 'Account and AgentBot IDs must be positive integers' unless valid_ids

    validate_url!
    pins = binding.fetch('ip_addresses')
    raise ArgumentError, 'Private AgentBot IP pins must be an array' unless pins.is_a?(Array)

    @addresses = pins.map { |address| private_address(address) }
    raise ArgumentError, 'Private AgentBot IP pins must not be empty' if @addresses.empty?
  end

  def authorized?(payload, secret)
    return false unless payload.is_a?(Hash) && payload.with_indifferent_access.dig(:account, :id) == @account_id
    return false unless secret.is_a?(String) && secret.present?

    bot = AgentBot.find_by!(id: @agent_bot_id, account_id: @account_id)
    bot.outgoing_url == @url && ActiveSupport::SecurityUtils.secure_compare(bot.secret, secret)
  end

  def fetch(url, **, &)
    raise SafeFetch::UnsafeUrlError, 'Private AgentBot URL changed' unless url == @url

    request = Options.new(url: url, **)
    raise SafeFetch::UnsupportedMethodError, 'Private AgentBot delivery requires POST' unless request.method == :post

    request.pinned_addresses = @addresses
    Fetcher.new(request).fetch(&)
  rescue SsrfFilter::Error, Resolv::ResolvError => e
    raise SafeFetch::UnsafeUrlError, e.message
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
    raise SafeFetch::FetchError, e.message
  end

  private

  def validate_url!
    valid = %w[http https].include?(@uri.scheme) && @uri.hostname.present? && (1..65_535).cover?(@uri.port) &&
            [@uri.userinfo, @uri.query, @uri.fragment].all?(&:nil?) && @uri.path.match?(%r{\A/webhook/[a-zA-Z0-9_-]+(?:/[a-zA-Z0-9_-]+)*\z})
    raise ArgumentError, 'Invalid private AgentBot webhook URL' unless valid
  end

  def private_address(value)
    raise ArgumentError, 'Private AgentBot IP pins must be exact addresses' unless value.is_a?(String) && value.exclude?('/') && value.exclude?('%')

    address = IPAddr.new(value)
    permitted = address.private? && !address.ipv4_mapped? && address != IPAddr.new('fd00:ec2::254')
    raise ArgumentError, 'Only private unicast IP pins are permitted' unless permitted

    address
  end
end

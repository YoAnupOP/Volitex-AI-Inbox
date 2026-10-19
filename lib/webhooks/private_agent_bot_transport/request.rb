class Webhooks::PrivateAgentBotTransport::Request < SafeFetch::PrivateNetworkRequest
  private

  def http_options(uri, ip_address)
    super.merge(proxy_from_env: false)
  end

  def redirect_location(response, _uri)
    raise SafeFetch::UnsafeUrlError, 'Private AgentBot redirects are forbidden' if response.is_a?(Net::HTTPRedirection)
  end
end

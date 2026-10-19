class Webhooks::PrivateAgentBotTransport::Options < SafeFetch::RequestOptions
  attr_accessor :pinned_addresses

  def resolver
    proc do |hostname|
      addresses = super().call(hostname)
      raise SsrfFilter::UnresolvedHostname, 'Private AgentBot hostname did not resolve' if addresses.empty?
      raise SsrfFilter::PrivateIPAddress, 'Private AgentBot DNS did not match IP pins' unless addresses.all? { |ip| pinned_addresses.include?(ip) }

      addresses
    end
  end
end

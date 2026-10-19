class Webhooks::PrivateAgentBotTransport::Fetcher < SafeFetch::Fetcher
  private

  def perform_request(&)
    Webhooks::PrivateAgentBotTransport::Request.new(options).perform(&)
  end
end

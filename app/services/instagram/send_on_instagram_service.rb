class Instagram::SendOnInstagramService < Instagram::BaseSendService
  private

  def channel_class
    Channel::Instagram
  end

  # Deliver a message with the given payload.
  # https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api
  def send_message(message_content)
    access_token = channel.valid_access_token
    @instagram_access_token = access_token
    if access_token.blank?
      Messages::StatusUpdateService.new(message, 'failed', 'Instagram authorization is unavailable. Reconnect this inbox.').perform
      return
    end
    query = { access_token: access_token }
    instagram_id = channel.instagram_id.presence || 'me'

    response = HTTParty.post(
      "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}/#{instagram_id}/messages",
      body: message_content,
      query: query,
      **http_timeouts
    )

    process_response(response, message_content)
  end

  def merge_human_agent_tag(params)
    global_config = GlobalConfig.get('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')

    return params unless ActiveModel::Type::Boolean.new.cast(global_config['ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT'])
    return params unless human_reply?
    return params if Conversations::MessageWindowService.new(conversation, human_agent: false).can_reply?
    return params unless Conversations::MessageWindowService.new(conversation).can_reply?

    params[:messaging_type] = 'MESSAGE_TAG'
    params[:tag] = 'HUMAN_AGENT'
    params
  end
end

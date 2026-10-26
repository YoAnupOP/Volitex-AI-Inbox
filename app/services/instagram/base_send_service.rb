class Instagram::BaseSendService < Base::SendOnChannelService
  pattr_initialize [:message!]
  HTTP_OPEN_TIMEOUT = 5
  HTTP_READ_TIMEOUT = 15

  private

  delegate :additional_attributes, to: :contact

  def perform_reply
    if replying_to_comment?
      send_comment_reply
      return
    end

    return fail_closed_window unless instagram_reply_allowed?

    send_attachments if message.attachments.present?
    send_content if message.content.present?
  rescue StandardError => e
    handle_error(e)
  end

  # When the agent replies to a message that originated as an Instagram comment,
  # the reply must go to the comment thread (POST /{comment-id}/replies), not as a DM.
  def replying_to_comment?
    replied_message&.content_attributes&.dig('instagram_comment').present?
  end

  def send_comment_reply
    comment_id = replied_message.content_attributes['comment_id']
    response = Instagram::CommentsClient.new(channel).reply(comment_id, message.outgoing_content)

    # Comment replies return `id` (the new comment's ID), not `message_id`.
    message.update!(source_id: response['id'])
    response
  rescue Instagram::CommentsClient::RequestError => e
    Rails.logger.error("Instagram comment reply error: #{e.message}")
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
    nil
  end

  def replied_message
    return if message.content_attributes&.dig('in_reply_to').blank?

    @replied_message ||= message.conversation.messages.find_by(id: message.content_attributes['in_reply_to'])
  end

  def send_attachments
    message.attachments.each do |attachment|
      send_message(attachment_message_params(attachment))
    end
  end

  def instagram_reply_allowed?
    return true unless channel.is_a?(Channel::Instagram)

    Conversations::MessageWindowService.new(conversation, human_agent: human_reply?).can_reply?
  end

  def human_reply?
    message.outgoing? && message.sender.is_a?(User) && message.content_attributes['automation_rule_id'].blank? &&
      message.additional_attributes['campaign_id'].blank?
  end

  def fail_closed_window
    Messages::StatusUpdateService.new(message, 'failed', 'Instagram messaging window is closed for this sender.').perform
  end

  def send_content
    send_message(message_params)
  end

  def handle_error(error)
    ChatwootExceptionTracker.new(error, account: message.account, user: message.sender).capture_exception
  end

  def message_params
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        text: message.outgoing_content
      }
    }

    merge_human_agent_tag(params)
  end

  def attachment_message_params(attachment)
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.download_url
          }
        }
      }
    }

    merge_human_agent_tag(params)
  end

  def process_response(response, _message_content)
    parsed_response = response.parsed_response
    if response.success? && parsed_response['error'].blank?
      message.update!(source_id: parsed_response['message_id'])
      parsed_response
    else
      external_error = external_error(parsed_response)
      Rails.logger.error("Instagram send failed message_id=#{message.id} code=#{parsed_response.dig('error', 'code')}")
      Messages::StatusUpdateService.new(message, 'failed', external_error).perform
      nil
    end
  end

  def http_timeouts
    { open_timeout: HTTP_OPEN_TIMEOUT, timeout: HTTP_READ_TIMEOUT }
  end

  def external_error(response)
    error_message = response.dig('error', 'message')
    error_code = response.dig('error', 'code')

    # https://developers.facebook.com/docs/messenger-platform/error-codes
    # Access token has expired or become invalid. This may be due to a password change,
    # removal of the connected app from Instagram account settings, or other reasons.
    if error_code == 190 && channel.is_a?(Channel::Instagram)
      channel.reject_invalid_token!(@instagram_access_token)
    elsif error_code == 190
      channel.authorization_error!
    end

    "#{error_code} - #{error_message}"
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  # Methods to be implemented by child classes
  def send_message(message_content)
    raise NotImplementedError, 'Subclasses must implement send_message'
  end

  def merge_human_agent_tag(params)
    raise NotImplementedError, 'Subclasses must implement merge_human_agent_tag'
  end
end

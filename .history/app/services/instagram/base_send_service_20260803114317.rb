class Instagram::BaseSendService < Base::SendOnChannelService
  pattr_initialize [:message!]

  private

  delegate :additional_attributes, to: :contact

  def perform_reply
    if replying_to_comment?
      send_comment_reply
      return
    end

    send_attachments if message.attachments.present?
    send_content if message.content.present?
  rescue StandardError => e
    handle_error(e)
  end

  # When the agent replies to a message that originated as an Instagram comment,
  # the reply must go to the comment thread (POST /{comment-id}/replies), not as a DM.
  def replying_to_comment?
    message.in_reply_to&.content_attributes&.dig('instagram_comment').present?
  end

  def send_comment_reply
    comment_id = message.in_reply_to.content_attributes['comment_id']
    response = HTTParty.post(
      "https://graph.instagram.com/v22.0/#{comment_id}/replies",
      body: { message: message.outgoing_content },
      query: { access_token: channel.access_token }
    )

    parsed_response = response.parsed_response
    if response.success? && parsed_response['error'].blank?
      # Comment replies return `id` (the new comment's ID), not `message_id`
      message.update!(source_id: parsed_response['id'] || parsed_response['message_id'])
      parsed_response
    else
      external_error = external_error(parsed_response)
      Rails.logger.error("Instagram comment reply error: #{external_error}")
      Messages::StatusUpdateService.new(message, 'failed', external_error).perform
      nil
    end
  end

  def send_attachments
    message.attachments.each do |attachment|
      send_message(attachment_message_params(attachment))
    end
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

  def process_response(response, message_content)
    parsed_response = response.parsed_response
    if response.success? && parsed_response['error'].blank?
      message.update!(source_id: parsed_response['message_id'])
      parsed_response
    else
      external_error = external_error(parsed_response)
      Rails.logger.error("Instagram response: #{external_error} : #{message_content}")
      Messages::StatusUpdateService.new(message, 'failed', external_error).perform
      nil
    end
  end

  def external_error(response)
    error_message = response.dig('error', 'message')
    error_code = response.dig('error', 'code')

    # https://developers.facebook.com/docs/messenger-platform/error-codes
    # Access token has expired or become invalid. This may be due to a password change,
    # removal of the connected app from Instagram account settings, or other reasons.
    channel.authorization_error! if error_code == 190

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

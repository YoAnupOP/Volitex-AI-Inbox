class MetaDataDeletionJob < ApplicationJob
  queue_as :default

  def perform(user_id, confirmation_code)
    deletion_request = MetaDataDeletionRequest.find_by(confirmation_code: confirmation_code)
    return unless deletion_request

    deletion_request.update!(status: 'processing')

    begin
      # Find and anonymize contacts associated with this Meta user
      anonymize_contacts(user_id)

      # Delete messages
      delete_messages(user_id)

      # Mark as completed
      deletion_request.update!(status: 'completed', completed_at: Time.current)

      Rails.logger.info "Completed data deletion for Meta user_id: #{user_id}"
    rescue StandardError => e
      deletion_request.update!(status: 'failed', error_message: e.message)
      Rails.logger.error "Failed data deletion for Meta user_id: #{user_id}, error: #{e.message}"
      raise
    end
  end

  private

  def anonymize_contacts(user_id)
    # Find contacts linked to this Meta user via channel provider_config
    whatsapp_contacts = Contact.joins(inbox: :channel)
                               .where(channels: { type: 'Channel::Whatsapp' })
                               .where("channels.provider_config->>'user_id' = ?", user_id)

    instagram_contacts = Contact.joins(inbox: :channel)
                                .where(channels: { type: 'Channel::Instagram' })
                                .where("channels.provider_config->>'user_id' = ?", user_id)

    # Anonymize instead of delete (preserve conversation history for business)
    (whatsapp_contacts + instagram_contacts).uniq.each do |contact|
      contact.update!(
        name: "Deleted User #{SecureRandom.hex(4)}",
        email: nil,
        phone_number: nil,
        additional_attributes: {},
        custom_attributes: {}
      )
    end
  end

  def delete_messages(user_id)
    # Delete messages from channels linked to this Meta user
    channel_ids = Channel::Whatsapp.where("provider_config->>'user_id' = ?", user_id)
                                   .or(Channel::Instagram.where("provider_config->>'user_id' = ?", user_id))
                                   .pluck(:id)

    inbox_ids = Inbox.where(channel_id: channel_ids).pluck(:id)
    conversation_ids = Conversation.where(inbox_id: inbox_ids).pluck(:id)

    Message.where(conversation_id: conversation_ids).delete_all
  end
end

class MetaDataDeletionJob < ApplicationJob
  queue_as :default

  def perform(user_id, confirmation_code)
    deletion_request = MetaDataDeletionRequest.find_by(confirmation_code: confirmation_code, user_id: user_id)
    return unless deletion_request

    deletion_request.with_lock do
      next if deletion_request.status == 'completed'

      deletion_request.update!(status: 'processing', error_message: nil)
      erase_meta_owned_channel_data!(user_id)
      deletion_request.update!(status: 'completed', completed_at: Time.current)
    end
  rescue StandardError => e
    deletion_request&.update!(status: 'failed', error_message: e.message)
    Rails.logger.error("Meta data deletion failed request=#{confirmation_code}: #{e.class}: #{e.message}")
    raise
  end

  private

  # Meta supplies the app-scoped user ID. In this application that ID is stored
  # on the OAuth/Embedded-Signup channel, so deletion is deliberately scoped to
  # data in inboxes owned by those channels, not the entire Chatwoot account.
  def erase_meta_owned_channel_data!(user_id)
    channels = meta_owned_channels(user_id)
    inbox_ids = channels.filter_map { |channel| channel.inbox&.id }
    return if inbox_ids.empty?

    contact_inboxes = ContactInbox.where(inbox_id: inbox_ids)
    contact_ids = contact_inboxes.distinct.pluck(:contact_id)
    conversation_ids = Conversation.where(inbox_id: inbox_ids).pluck(:id)
    message_ids = Message.where(conversation_id: conversation_ids).pluck(:id)

    ActiveRecord::Base.transaction do
      purge_messages!(message_ids)
      CsatSurveyResponse.where(conversation_id: conversation_ids).delete_all
      Conversation.where(id: conversation_ids).destroy_all
      ContactInbox.where(id: contact_inboxes.select(:id)).destroy_all
      anonymize_contacts_without_other_inboxes!(contact_ids)

      # Destroying the inbox also removes the channel credentials and invokes
      # the channel's normal webhook teardown lifecycle.
      channels.each { |channel| channel.inbox&.destroy! }
    end
  end

  def meta_owned_channels(user_id)
    whatsapp = Channel::Whatsapp.where("provider_config->>'user_id' = ?", user_id)
    # Instagram Login returns this app-scoped Meta user ID as `instagram_id`.
    instagram = Channel::Instagram.where(instagram_id: user_id)
    whatsapp.to_a + instagram.to_a
  end

  def purge_messages!(message_ids)
    return if message_ids.empty?

    # Message#destroy purges ActiveStorage attachments via its association,
    # unlike delete_all which leaves binary PII and attachment rows behind.
    Message.where(id: message_ids).find_each(&:destroy!)
  end

  def anonymize_contacts_without_other_inboxes!(contact_ids)
    return if contact_ids.empty?

    shared_contact_ids = ContactInbox.where(contact_id: contact_ids).distinct.pluck(:contact_id)
    Contact.where(id: contact_ids - shared_contact_ids).find_each do |contact|
      contact.avatar.purge if contact.avatar.attached?
      Note.where(contact_id: contact.id).delete_all
      CsatSurveyResponse.where(contact_id: contact.id).delete_all
      # We intentionally bypass validations and callbacks: the related inbox and
      # conversations are already gone, and callbacks could re-create data.
      # rubocop:disable Rails/SkipsModelValidations
      contact.update_columns(
        name: "Deleted Meta User #{SecureRandom.hex(8)}",
        email: nil,
        phone_number: nil,
        identifier: nil,
        additional_attributes: {},
        custom_attributes: {},
        location: '',
        last_name: '',
        middle_name: ''
      )
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end

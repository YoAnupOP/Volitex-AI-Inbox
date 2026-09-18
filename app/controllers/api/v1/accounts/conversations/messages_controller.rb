class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_api_inbox, only: :update

  def index
    @messages = message_finder.perform
  end

  def create
    return render_automation_owner_error unless permitted_by_automation_owner?
    return render_existing_automation_delivery if existing_automation_delivery

    user = Current.user || @resource
    mb = Messages::MessageBuilder.new(user, @conversation, message_params_for_actor)
    @message = mb.perform
  rescue ActiveRecord::RecordNotUnique
    return render_existing_automation_delivery if existing_automation_delivery

    raise
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def update
    Messages::StatusUpdateService.new(message, permitted_params[:status], permitted_params[:external_error]).perform
    @message = message
  end

  def destroy
    delete_instagram_comment if instagram_comment?

    ActiveRecord::Base.transaction do
      message.update!(content: I18n.t('conversations.messages.deleted'), content_type: :text, content_attributes: { deleted: true })
      message.attachments.destroy_all
    end
  rescue Instagram::CommentsClient::RequestError => e
    render json: { error: e.message }, status: e.status
  end

  def retry
    return if message.blank?

    service = Messages::StatusUpdateService.new(message, 'sent')
    service.perform
    message.update!(content_attributes: {})
    ::SendReplyJob.perform_later(message.id)
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def translate
    return head :ok if already_translated_content_available?

    translated_content = Integrations::GoogleTranslate::ProcessorService.new(
      message: message,
      target_language: permitted_params[:target_language]
    ).perform

    if translated_content.present?
      translations = {}
      translations[permitted_params[:target_language]] = translated_content
      translations = message.translations.merge!(translations) if message.translations.present?
      message.update!(translations: translations)
    end

    render json: { content: translated_content }
  rescue Google::Cloud::Error => e
    # `details` carries the clean human message; `message` includes gRPC debug noise
    render_could_not_create_error(e.details.presence || e.message)
  end

  private

  def automation_ownership
    @automation_ownership ||= Conversations::AutomationOwnershipService.new(conversation: @conversation, actor: Current.user)
  end

  def permitted_by_automation_owner?
    if Current.user.is_a?(AgentBot)
      return true unless automation_ownership.n8n_bot?(Current.user)

      return automation_ownership.n8n_owner?(Current.user)
    end

    @conversation.custom_attributes.to_h['automation_owner'] != Conversations::AutomationOwnershipService::N8N_OWNER
  end

  def render_automation_owner_error
    message = Current.user.is_a?(AgentBot) ? 'n8n does not own this conversation.' : 'n8n owns this conversation. Take over before replying.'
    render json: { error: message }, status: :unprocessable_entity
  end

  def automation_delivery_id
    return unless Current.user.is_a?(AgentBot)

    params[:automation_delivery_id].presence
  end

  def existing_automation_delivery
    return unless automation_delivery_id

    @conversation.messages.find_by(source_id: automation_delivery_source_id)
  end

  def render_existing_automation_delivery
    @message = existing_automation_delivery
    render :create, status: :ok
  end

  def message_params_for_actor
    return params unless Current.user.is_a?(AgentBot) && automation_ownership.n8n_bot?(Current.user)

    raise ArgumentError, 'automation_delivery_id is required for n8n replies' if automation_delivery_id.blank?

    params.deep_dup.tap do |message_params|
      content_attributes = message_params[:content_attributes]
      content_attributes = content_attributes.to_unsafe_h if content_attributes.is_a?(ActionController::Parameters)
      content_attributes = content_attributes.to_h.merge('automation_delivery_id' => automation_delivery_id)
      message_params[:content_attributes] = content_attributes
      message_params[:sender_type] = 'AgentBot'
      message_params[:sender_id] = Current.user.id
      message_params[:source_id] = automation_delivery_source_id
    end
  end

  def automation_delivery_source_id
    "volitex:n8n:#{Current.user.id}:#{automation_delivery_id}"
  end

  def instagram_comment?
    message.content_attributes&.dig('instagram_comment').present?
  end

  def delete_instagram_comment
    comment_id = message.content_attributes['comment_id']
    channel = @conversation.inbox.channel
    return unless channel.is_a?(Channel::Instagram)

    Instagram::CommentsClient.new(channel).delete(comment_id)
  end

  def message
    @message ||= @conversation.messages.find(permitted_params[:id])
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end

  def permitted_params
    params.permit(:id, :target_language, :status, :external_error)
  end

  def already_translated_content_available?
    message.translations.present? && message.translations[permitted_params[:target_language]].present?
  end

  # API inbox check
  def ensure_api_inbox
    # Only API inboxes can update messages
    render json: { error: 'Message status update is only allowed for API inboxes' }, status: :forbidden unless @conversation.inbox.api?
  end
end

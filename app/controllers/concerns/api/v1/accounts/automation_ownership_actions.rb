module Api::V1::Accounts::AutomationOwnershipActions
  extend ActiveSupport::Concern

  def custom_attributes
    attributes = params.permit(custom_attributes: {})[:custom_attributes].to_h
    if attributes.keys.intersect?(Conversations::AutomationOwnershipService::RESERVED_ATTRIBUTE_KEYS)
      return render json: { error: 'Automation ownership can only be changed with toggle_ai_mode.' }, status: :unprocessable_entity
    end

    @conversation.custom_attributes = attributes
    @conversation.save!
  end

  # This is the only supported ownership transition for the Volitex AI Inbox n8n control plane.
  def toggle_ai_mode
    ai_mode = params[:ai_mode].to_s == 'true'
    ownership = Conversations::AutomationOwnershipService.new(conversation: @conversation, actor: Current.user)
    ai_mode ? ownership.enable_n8n! : ownership.handoff_to_human!

    render json: {
      ai_mode: ai_mode,
      automation_owner: @conversation.reload.custom_attributes['automation_owner'],
      conversation_id: @conversation.id
    }
  end
end

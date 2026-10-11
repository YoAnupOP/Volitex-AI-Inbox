module Api::V1::Accounts::QuickMenuSending
  extend ActiveSupport::Concern

  def send_quick_menu
    quick_menu = Current.account.quick_menus.find(params.permit(:quick_menu_id).require(:quick_menu_id))
    authorize quick_menu, :show?
    message = QuickMenus::SendService.new(conversation: @conversation, quick_menu: quick_menu, user: Current.user).perform
    render json: message.attributes.slice('id', 'content', 'content_type', 'content_attributes', 'status'),
           status: :created
  rescue ActionController::ParameterMissing => e
    render_quick_menu_error('invalid_request', e.message, :unprocessable_entity)
  rescue ActiveRecord::RecordInvalid => e
    render_quick_menu_error('message_rejected', e.record.errors.full_messages.to_sentence, :unprocessable_entity)
  rescue QuickMenus::SendService::Error => e
    render_quick_menu_error(e.code, e.message, :unprocessable_entity)
  end

  private

  def render_quick_menu_error(code, message, status)
    render json: { error: { code: code, message: message } }, status: status
  end
end

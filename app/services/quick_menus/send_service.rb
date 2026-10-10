class QuickMenus::SendService
  class Error < StandardError
    attr_reader :code

    def initialize(code, message)
      @code = code
      super(message)
    end
  end

  def initialize(conversation:, quick_menu:, user:)
    @conversation = conversation
    @quick_menu = quick_menu
    @user = user
  end

  def perform
    validate_sendable!
    Messages::MessageBuilder.new(@user, @conversation, message_params).perform
  end

  private

  def validate_sendable!
    raise Error.new('invalid_menu', @quick_menu.errors.full_messages.to_sentence) unless @quick_menu.valid?
    raise Error.new('unsupported_inbox', 'Quick Menus can only be sent from a WhatsApp Cloud inbox.') unless cloud_whatsapp_inbox?
    raise Error.new('window_closed', 'The WhatsApp customer-service window is closed.') unless @conversation.can_reply?
  end

  def cloud_whatsapp_inbox?
    inbox = @conversation.inbox
    channel = inbox.channel
    @conversation.account_id == @quick_menu.account_id && inbox.account_id == @quick_menu.account_id &&
      channel.account_id == @quick_menu.account_id &&
      channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'
  end

  def message_params
    ActionController::Parameters.new(
      content: @quick_menu.body,
      content_type: 'input_select',
      message_type: 'outgoing',
      private: false,
      content_attributes: { items: message_items }
    )
  end

  def message_items
    @quick_menu.items.each_with_index.map do |item, index|
      { title: item.fetch('title'), value: "qm#{@quick_menu.id}_#{index + 1}" }
    end
  end
end

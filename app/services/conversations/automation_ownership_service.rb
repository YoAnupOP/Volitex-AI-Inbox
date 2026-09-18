class Conversations::AutomationOwnershipService
  N8N_OWNER = 'n8n'.freeze
  HUMAN_OWNER = 'human'.freeze
  RESERVED_ATTRIBUTE_KEYS = %w[ai_mode automation_owner automation_agent_bot_id automation_handoff_at].freeze

  def initialize(conversation:, actor:)
    @conversation = conversation
    @actor = actor
  end

  def enable_n8n!
    raise Pundit::NotAuthorizedError unless actor.is_a?(User)

    conversation.reload
    conversation.with_lock do
      bot = conversation.inbox.agent_bot
      raise ArgumentError, 'This inbox does not have a Volitex n8n AgentBot' unless n8n_bot?(bot)

      update_ownership!(N8N_OWNER, bot)
    end
  end

  def handoff_to_human!
    raise Pundit::NotAuthorizedError unless actor.is_a?(User)

    conversation.reload
    conversation.with_lock do
      update_ownership!(HUMAN_OWNER, nil)
      conversation.assignee = actor
      conversation.assignee_agent_bot = nil
      conversation.save!
    end
  end

  def n8n_owner?(bot)
    attributes = conversation.custom_attributes.to_h
    attributes['automation_owner'] == N8N_OWNER &&
      attributes['automation_agent_bot_id'].to_s == bot.id.to_s &&
      conversation.assignee_agent_bot_id == bot.id &&
      n8n_bot?(bot)
  end

  def self.system_handoff!(conversation)
    conversation.reload
    conversation.with_lock do
      attributes = conversation.custom_attributes.to_h
      if attributes['automation_owner'] == N8N_OWNER
        conversation.custom_attributes = attributes.merge(
          'ai_mode' => false,
          'automation_owner' => HUMAN_OWNER,
          'automation_agent_bot_id' => nil,
          'automation_handoff_at' => Time.current.iso8601
        ).compact
        conversation.assignee_agent_bot = nil
        conversation.save!
      end
    end
  end

  def n8n_bot?(bot)
    bot.present? &&
      bot.account_id == conversation.account_id &&
      bot.bot_config.to_h['volitex_control_plane'] == 'n8n' &&
      conversation.inbox.agent_bot_inbox&.active? &&
      conversation.inbox.agent_bot&.id == bot.id
  end

  private

  attr_reader :conversation, :actor

  def update_ownership!(owner, bot)
    attributes = conversation.custom_attributes.to_h.merge(
      'ai_mode' => owner == N8N_OWNER,
      'automation_owner' => owner,
      'automation_agent_bot_id' => bot&.id,
      'automation_handoff_at' => Time.current.iso8601
    ).compact
    conversation.custom_attributes = attributes
    conversation.assignee = nil if bot.present?
    conversation.assignee_agent_bot = bot
    conversation.save!
  end
end

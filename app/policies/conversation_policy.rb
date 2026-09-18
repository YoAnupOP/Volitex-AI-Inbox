class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def destroy?
    administrator?
  end

  def show?
    administrator? || agent_bot? || agent_can_view_conversation?
  end

  private

  def agent_can_view_conversation?
    inbox_access? || team_access?
  end

  def administrator?
    account_user&.administrator?
  end

  def agent_bot?
    return false unless user.is_a?(AgentBot) && user.account_id == account.id && user.inboxes.exists?(id: record.inbox_id)
    return true unless user.bot_config.to_h['volitex_control_plane'] == 'n8n'

    record.assignee_agent_bot_id == user.id &&
      record.custom_attributes.to_h['automation_owner'] == Conversations::AutomationOwnershipService::N8N_OWNER
  end

  def inbox_access?
    user.inboxes.where(account_id: account&.id).exists?(id: record.inbox_id)
  end

  def team_access?
    return false if record.team_id.blank?

    user.teams.where(account_id: account&.id).exists?(id: record.team_id)
  end

  def assigned_to_user?
    record.assignee_id == user.id
  end

  def participant?
    record.conversation_participants.exists?(user_id: user.id)
  end
end

ConversationPolicy.prepend_mod_with('ConversationPolicy')

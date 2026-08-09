class ActionCableBroadcastJob < ApplicationJob
  queue_as :critical
  include Events::Types

  CONVERSATION_UPDATE_EVENTS = [
    CONVERSATION_READ,
    CONVERSATION_UPDATED,
    TEAM_CHANGED,
    ASSIGNEE_CHANGED,
    CONVERSATION_STATUS_CHANGED
  ].freeze

  def perform(members, event_name, data)
    return if members.blank?

    log_broadcast_success('action_cable.broadcast.attempt', members, event_name, data)
    broadcast_data = prepare_broadcast_data(event_name, data)
    broadcast_to_members(members, event_name, broadcast_data)
    log_broadcast_success('action_cable.broadcast.completed', members, event_name, data)
  rescue StandardError => e
    Rails.logger.error(
      { event: 'action_cable.broadcast.failed', event_name: event_name, error_class: e.class.name, account_id: data[:account_id] }.to_json
    )
    raise
  end

  private

  def log_broadcast_success(event, members, event_name, data)
    return unless ENV['ACTION_CABLE_DIAGNOSTICS'] == 'true'

    Rails.logger.info(
      { event: event, event_name: event_name, member_count: members.size, account_id: data[:account_id] }.to_json
    )
  end

  # Ensures that only the latest available data is sent to prevent UI issues
  # caused by out-of-order events during high-traffic periods. This prevents
  # the conversation job from processing outdated data.
  def prepare_broadcast_data(event_name, data)
    return data unless CONVERSATION_UPDATE_EVENTS.include?(event_name)

    account = Account.find(data[:account_id])
    conversation = account.conversations.find_by!(display_id: data[:id])
    conversation.push_event_data.merge(account_id: data[:account_id])
  end

  def broadcast_to_members(members, event_name, broadcast_data)
    members.each do |member|
      ActionCable.server.broadcast(
        member,
        {
          event: event_name,
          data: broadcast_data
        }
      )
    end
  end
end

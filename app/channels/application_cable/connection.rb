class ApplicationCable::Connection < ActionCable::Connection::Base
  def connect
    Rails.logger.info({ event: 'action_cable.connection.opened', connection_id: connection_identifier }.to_json)
  end

  def disconnect
    Rails.logger.info({ event: 'action_cable.connection.closed', connection_id: connection_identifier }.to_json)
  end
end

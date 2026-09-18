class AddAutomationDeliveryIdIndexToMessages < ActiveRecord::Migration[7.0]
  def change
    add_index :messages,
              [:sender_type, :sender_id, :source_id],
              unique: true,
              where: "sender_type = 'AgentBot' AND source_id LIKE 'volitex:n8n:%'",
              name: 'index_messages_on_n8n_delivery_source_id'
  end
end

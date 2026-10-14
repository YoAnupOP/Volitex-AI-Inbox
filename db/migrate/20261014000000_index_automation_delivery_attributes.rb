class IndexAutomationDeliveryAttributes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # Message uses a JSON-coded store: the json column contains a JSON string.
    # The immutable automation key must survive replacement of source_id by Meta.
    delivery = "((content_attributes #>> '{}')::jsonb ->> 'automation_delivery_id')"
    add_index :messages, "conversation_id, sender_id, #{delivery}",
              unique: true, where: "sender_type = 'AgentBot' AND #{delivery} IS NOT NULL",
              name: 'index_messages_on_automation_delivery', algorithm: :concurrently
  end
end

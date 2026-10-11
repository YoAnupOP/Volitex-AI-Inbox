class EnsureAutomationDeliveryIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_messages_on_n8n_delivery_source_id'.freeze
  PREDICATE = "sender_type = 'AgentBot' AND source_id LIKE 'volitex:n8n:%'".freeze

  def up
    if index_name_exists?(:messages, INDEX_NAME)
      valid = select_value("SELECT indisvalid FROM pg_index WHERE indexrelid = to_regclass(#{quote(INDEX_NAME)})")
      return if valid && index_exists?(:messages, %i[sender_type sender_id source_id], unique: true, name: INDEX_NAME)

      raise ActiveRecord::MigrationError, "Inspect invalid or unexpected #{INDEX_NAME} before retrying; no index was removed."
    end

    duplicate_count = select_value(<<~SQL.squish).to_i
      SELECT COUNT(*) FROM (
        SELECT sender_type, sender_id, source_id FROM messages
        WHERE #{PREDICATE}
        GROUP BY sender_type, sender_id, source_id HAVING COUNT(*) > 1
      ) duplicates
    SQL
    if duplicate_count.positive?
      raise ActiveRecord::MigrationError,
            "Resolve #{duplicate_count} duplicate n8n delivery groups intentionally before retrying; no data was deleted."
    end

    add_index :messages, %i[sender_type sender_id source_id],
              unique: true, where: PREDICATE, name: INDEX_NAME, algorithm: :concurrently
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'The n8n idempotency index may predate this repair and must be preserved.'
  end
end

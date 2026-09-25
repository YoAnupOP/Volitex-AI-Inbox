class AddUniqueIncomingMessageSourcePerInbox < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_messages_on_inbox_incoming_source_id'.freeze

  def up
    duplicate_count = duplicate_incoming_source_group_count

    if duplicate_count.positive?
      raise ActiveRecord::MigrationError,
            "Cannot add #{INDEX_NAME}: #{duplicate_count} duplicate incoming (inbox_id, source_id) groups exist. " \
            'Resolve them intentionally, without deleting production data, then rerun this migration. '
    end

    add_index :messages,
              %i[inbox_id source_id],
              unique: true,
              where: 'message_type = 0 AND source_id IS NOT NULL',
              name: INDEX_NAME,
              algorithm: :concurrently
  end

  def down
    remove_index :messages, name: INDEX_NAME, algorithm: :concurrently
  end

  private

  def duplicate_incoming_source_group_count
    select_value(<<~SQL.squish).to_i
      SELECT COUNT(*)
      FROM (
        SELECT inbox_id, source_id
        FROM messages
        WHERE message_type = 0 AND source_id IS NOT NULL
        GROUP BY inbox_id, source_id
        HAVING COUNT(*) > 1
      ) duplicates
    SQL
  end
end

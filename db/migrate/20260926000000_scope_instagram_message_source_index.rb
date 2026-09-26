class ScopeInstagramMessageSourceIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_messages_on_inbox_incoming_source_id'.freeze

  def up
    mark_existing_instagram_messages
    duplicate_count = duplicate_incoming_source_group_count

    if duplicate_count.positive?
      raise ActiveRecord::MigrationError,
            "Cannot replace #{INDEX_NAME}: #{duplicate_count} duplicate Instagram (inbox_id, source_id) groups exist. " \
            'Resolve them intentionally, without deleting production data, then rerun this migration. '
    end

    remove_index :messages, name: INDEX_NAME, algorithm: :concurrently if index_exists?(:messages, name: INDEX_NAME)

    add_index :messages,
              %i[inbox_id source_id],
              unique: true,
              where: instagram_incoming_message_predicate,
              name: INDEX_NAME,
              algorithm: :concurrently
  end

  def down
    remove_index :messages, name: INDEX_NAME, algorithm: :concurrently if index_exists?(:messages, name: INDEX_NAME)
  end

  private

  def duplicate_incoming_source_group_count
    select_value(<<~SQL.squish).to_i
      SELECT COUNT(*)
      FROM (
        SELECT inbox_id, source_id
        FROM messages
        WHERE #{instagram_incoming_message_predicate}
        GROUP BY inbox_id, source_id
        HAVING COUNT(*) > 1
      ) duplicates
    SQL
  end

  def mark_existing_instagram_messages
    execute <<~SQL.squish
      UPDATE messages
      SET content_attributes = (COALESCE(content_attributes::jsonb, '{}'::jsonb) || '{"inbound_source":"instagram"}'::jsonb)::json
      WHERE message_type = 0
        AND source_id IS NOT NULL
        AND (content_attributes ->> 'inbound_source') IS DISTINCT FROM 'instagram'
        AND EXISTS (
          SELECT 1
          FROM inboxes
          LEFT JOIN channel_facebook_pages ON channel_facebook_pages.id = inboxes.channel_id
            AND inboxes.channel_type = 'Channel::FacebookPage'
          WHERE inboxes.id = messages.inbox_id
            AND (
              inboxes.channel_type = 'Channel::Instagram'
              OR channel_facebook_pages.instagram_id IS NOT NULL
            )
        )
    SQL
  end

  def instagram_incoming_message_predicate
    "message_type = 0 AND source_id IS NOT NULL AND content_attributes ->> 'inbound_source' = 'instagram'"
  end
end

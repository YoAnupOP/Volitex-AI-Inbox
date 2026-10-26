class TrackInstagramConnectionHealth < ActiveRecord::Migration[7.1]
  def up
    add_column :channel_instagram, :token_refreshed_at, :datetime
    add_column :channel_instagram, :subscription_verified_at, :datetime
    add_index :channel_instagram, :expires_at
    execute 'UPDATE channel_instagram SET token_refreshed_at = updated_at'
  end

  def down
    remove_index :channel_instagram, :expires_at
    remove_column :channel_instagram, :subscription_verified_at
    remove_column :channel_instagram, :token_refreshed_at
  end
end

class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    Conversation.reset_column_information
    # The current acts-as-taggable-on release removed this legacy constant.
    # Conversation already includes the taggable cache behavior at application
    # boot, so fresh installs only need the column migration.
  end
end

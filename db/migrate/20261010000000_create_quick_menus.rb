class CreateQuickMenus < ActiveRecord::Migration[7.1]
  def change
    create_table :quick_menus do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.text :body, null: false
      t.jsonb :items, null: false, default: []
      t.timestamps
    end

    add_check_constraint :quick_menus, 'char_length(body) BETWEEN 1 AND 1024 AND length(btrim(body)) > 0',
                         name: 'quick_menus_body_length_check'
    add_check_constraint :quick_menus,
                         "CASE WHEN jsonb_typeof(items) = 'array' THEN jsonb_array_length(items) BETWEEN 1 AND 10 ELSE false END",
                         name: 'quick_menus_items_count_check'
  end
end

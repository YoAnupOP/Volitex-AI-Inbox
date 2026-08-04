class CreateMetaDataDeletionRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :meta_data_deletion_requests do |t|
      t.string :user_id, null: false
      t.string :confirmation_code, null: false
      t.string :status, default: 'pending', null: false
      t.text :error_message
      t.datetime :requested_at, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :meta_data_deletion_requests, :confirmation_code, unique: true
    add_index :meta_data_deletion_requests, :user_id
    add_index :meta_data_deletion_requests, :status
  end
end

class CreateCampaignDeliveries < ActiveRecord::Migration[7.1]
  def change
    add_campaign_state_columns
    create_table :campaign_recipients do |t|
      t.references :campaign, null: false, foreign_key: { on_delete: :cascade }
      t.references :contact, foreign_key: { on_delete: :nullify }
      t.string :phone_number, null: false
      t.string :state, null: false, default: 'pending'
      t.integer :attempts, null: false, default: 0
      t.datetime :next_attempt_at
      t.datetime :claimed_at
      t.string :provider_message_id
      t.jsonb :consent_snapshot, null: false, default: {}
      t.string :error_code
      t.timestamps
    end
    add_delivery_indexes
    add_delivery_constraints
    create_dispatch_slots
  end

  private

  def add_campaign_state_columns
    add_column :campaigns, :audience_snapshotted_at, :datetime
    add_column :campaigns, :delivery_error, :string
    add_column :campaigns, :dispatch_token, :string
    add_column :campaigns, :dispatch_scheduled_at, :datetime
  end

  def create_dispatch_slots
    create_table :campaign_dispatch_slots do |t|
      t.references :inbox, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.datetime :available_at, null: false
      t.timestamps
    end
  end

  def add_delivery_indexes
    add_index :campaign_recipients, [:campaign_id, :contact_id], unique: true
    add_index :campaign_recipients, [:campaign_id, :state, :next_attempt_at], name: 'index_campaign_recipients_dispatch'
    add_index :campaign_recipients, [:campaign_id, :phone_number], unique: true, where: "phone_number != ''",
                                                                   name: 'index_campaign_recipients_destination'
    add_index :campaign_recipients, :provider_message_id, unique: true, where: 'provider_message_id IS NOT NULL'
  end

  def add_delivery_constraints
    add_check_constraint :campaign_recipients,
                         "state IN ('pending','sending','retryable','accepted','sent','delivered','read'," \
                         "'failed','unknown','suppressed','cancelled')", name: 'campaign_recipient_state'
    add_check_constraint :campaign_recipients, 'attempts >= 0 AND attempts <= 3', name: 'campaign_recipient_attempts'
  end
end

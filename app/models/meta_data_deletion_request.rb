# == Schema Information
#
# Table name: meta_data_deletion_requests
#
#  id                :bigint           not null, primary key
#  completed_at      :datetime
#  confirmation_code :string           not null
#  error_message     :text
#  requested_at      :datetime         not null
#  status            :string           default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :string           not null
#
# Indexes
#
#  index_meta_data_deletion_requests_on_confirmation_code  (confirmation_code) UNIQUE
#  index_meta_data_deletion_requests_on_status             (status)
#  index_meta_data_deletion_requests_on_user_id            (user_id)
#
class MetaDataDeletionRequest < ApplicationRecord
  validates :user_id, presence: true
  validates :confirmation_code, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }

  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
end

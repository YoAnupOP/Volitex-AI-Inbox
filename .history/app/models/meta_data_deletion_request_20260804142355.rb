class MetaDataDeletionRequest < ApplicationRecord
  validates :user_id, presence: true
  validates :confirmation_code, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }

  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
end

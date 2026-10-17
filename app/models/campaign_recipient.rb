class CampaignRecipient < ApplicationRecord
  STATES = %w[pending sending retryable accepted sent delivered read failed unknown suppressed cancelled].freeze
  DELIVERY_ORDER = %w[accepted sent delivered read].freeze
  belongs_to :campaign
  belongs_to :contact, optional: true
  validates :state, inclusion: { in: STATES }
  validates :contact_id, uniqueness: { scope: :campaign_id }, allow_nil: true
  validate :same_account

  scope :unfinished, -> { where(state: %w[pending sending retryable]) }

  def eligible?
    return false unless contact && contact.account_id == campaign.account_id

    !contact.blocked? && contact.phone_number.present? && contact.phone_number == phone_number && consent_granted?
  end

  def consent_granted?
    consent = contact.custom_attributes['whatsapp_marketing_consent']
    return false unless consent.is_a?(Hash) && consent['status'] == 'granted'
    return false unless consent['source'].present? && consent['inbox_id'].to_s == campaign.inbox_id.to_s

    Time.iso8601(consent['recorded_at'].to_s) <= Time.current
  rescue ArgumentError
    false
  end

  def reconcile!(status)
    incoming = status[:status]
    return unless (DELIVERY_ORDER + ['failed']).include?(incoming)

    with_lock do
      # A late failure must not undo delivery; delayed sent must not undo read.
      next if %w[delivered read].include?(state) && incoming == 'failed'
      next if incoming != 'failed' && DELIVERY_ORDER.index(incoming).to_i < DELIVERY_ORDER.index(state).to_i

      update!(state: incoming, error_code: status.dig(:errors, 0, :code)&.to_s)
    end
  end

  private

  def same_account
    errors.add(:contact, 'must belong to campaign account') if contact && campaign && contact.account_id != campaign.account_id
  end
end

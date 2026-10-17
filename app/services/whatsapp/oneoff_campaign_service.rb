class Whatsapp::OneoffCampaignService
  class InvalidAudience < StandardError; end

  pattr_initialize [:campaign!]

  def perform
    campaign.with_lock do
      return unless campaign.active? && campaign.enabled?

      validate!
      snapshot_audience
      campaign.update!(campaign_status: :processing, audience_snapshotted_at: Time.current)
    end
    campaign.enqueue_dispatch if campaign.processing?
  rescue Whatsapp::CampaignTemplateService::InvalidTemplate, InvalidAudience
    campaign.update!(campaign_status: :failed, delivery_error: 'invalid_template_or_audience')
  end

  private

  def validate!
    raise 'WhatsApp campaigns feature not enabled' unless campaign.account.feature_enabled?(:whatsapp_campaign)
    raise 'WhatsApp Cloud provider required' unless campaign.inbox.channel.try(:provider) == 'whatsapp_cloud'
    raise 'Invalid campaign' unless campaign.one_off? && campaign.inbox.inbox_type == 'Whatsapp'

    Whatsapp::CampaignTemplateService.new(campaign: campaign).validate!
  end

  def snapshot_audience
    labels = audience_labels

    campaign.account.contacts.tagged_with(labels, any: true).select(:id, :phone_number, :account_id, :custom_attributes,
                                                                    :blocked).find_in_batches(batch_size: 500) do |contacts|
      # Bounded inserts from an account-scoped query. Database constraints enforce delivery identity/state.
      CampaignRecipient.insert_all(contacts.map { |contact| snapshot_row(contact) }, unique_by: :index_campaign_recipients_destination) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def audience_labels
    audience = Array(campaign.audience)
    raise InvalidAudience, 'Label audience required' unless audience.all? { |item| item.is_a?(Hash) && item['type'] == 'Label' }

    ids = audience.pluck('id').map(&:to_s).uniq
    labels = campaign.account.labels.where(id: ids).pluck(:title)
    raise InvalidAudience, 'Account labels required' if ids.empty? || labels.length != ids.length

    labels
  end

  def snapshot_row(contact)
    eligible = CampaignRecipient.new(campaign: campaign, contact: contact, phone_number: contact.phone_number.to_s).eligible?
    { campaign_id: campaign.id, contact_id: contact.id, phone_number: contact.phone_number.to_s,
      state: eligible ? 'pending' : 'suppressed', error_code: eligible ? nil : 'consent_or_contact_ineligible',
      created_at: Time.current, updated_at: Time.current }
  end
end

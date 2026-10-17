class Whatsapp::CampaignDispatchService
  pattr_initialize [:campaign!]

  def perform
    recipient = claim
    send_recipient(recipient) if recipient
  end

  private

  def claim
    campaign.with_lock do
      return unless dispatchable?

      campaign.campaign_recipients.where(state: 'sending').where(claimed_at: ...2.minutes.ago).find_each do |recipient|
        recipient.update!(state: 'unknown', error_code: 'worker_lost_after_claim')
      end
      recipient = campaign.campaign_recipients.where(state: %w[pending retryable])
                          .where('next_attempt_at IS NULL OR next_attempt_at <= ?', Time.current).first
      return finalize unless recipient

      reserve(recipient)
    end
  end

  def dispatchable?
    return false unless campaign.campaign_dispatch_enabled?
    return true if campaign.inbox.inbox_type == 'Whatsapp' && campaign.inbox.channel.provider == 'whatsapp_cloud'

    campaign.update!(campaign_status: :paused, delivery_error: 'unsupported_inbox')
    false
  end

  def finalize
    return if campaign.campaign_recipients.unfinished.exists?

    errors = campaign.campaign_recipients.exists?(state: %w[failed unknown])
    campaign.update!(campaign_status: errors ? :completed_with_errors : :completed)
    nil
  end

  def reserve(recipient)
    slot = CampaignDispatchSlot.create_or_find_by!(inbox: campaign.inbox) { |record| record.available_at = Time.current }
    slot.with_lock do
      return if slot.available_at > Time.current

      slot.update!(available_at: 1.second.from_now)
      recipient.update!(state: 'sending', attempts: recipient.attempts + 1, claimed_at: Time.current)
    end
    recipient
  end

  def send_recipient(recipient)
    recipient.contact&.reload
    unless recipient.eligible?
      recipient.update!(state: 'suppressed', error_code: 'consent_or_contact_ineligible')
      return
    end

    recipient.update!(consent_snapshot: recipient.contact.custom_attributes.fetch('whatsapp_marketing_consent'))
    persist_result(recipient, deliver(recipient))
  rescue Whatsapp::CampaignTemplateService::InvalidTemplate
    persist_result(recipient, { state: 'failed', error_code: 'invalid_template' })
  rescue Net::OpenTimeout, SocketError, Errno::ECONNREFUSED
    persist_result(recipient, { state: 'retryable', error_code: 'connection_not_established' })
  rescue StandardError => e
    # Do not log response bodies, phone numbers, credentials or exception messages.
    recipient.with_lock { recipient.update!(state: 'unknown', error_code: e.class.name.first(120)) if recipient.state == 'sending' }
  end

  def deliver(recipient)
    info = Whatsapp::CampaignTemplateService.new(campaign: campaign).for_contact(recipient.contact)
    provider = Whatsapp::Providers::CloudCampaignService.new(whatsapp_channel: campaign.inbox.channel)
    provider.send_campaign_template(recipient.phone_number, info, recipient_id: recipient.id)
  end

  def apply_backoff(delay)
    slot = CampaignDispatchSlot.find_by!(inbox_id: campaign.inbox_id)
    slot.with_lock { slot.update!(available_at: [slot.available_at, delay.seconds.from_now].max) }
  end

  def persist_result(recipient, result)
    state = result.fetch(:state)
    state = 'failed' if state == 'retryable' && recipient.attempts >= 3
    delay = [result.fetch(:retry_after, 0).to_i, 30 * (2**(recipient.attempts - 1))].max
    apply_backoff(delay) if state == 'retryable'
    recipient.with_lock do
      return unless %w[sending unknown].include?(recipient.state)

      recipient.update!(state: state, provider_message_id: result[:provider_message_id], error_code: result[:error_code],
                        next_attempt_at: state == 'retryable' ? delay.seconds.from_now : nil)
    end
  end
end

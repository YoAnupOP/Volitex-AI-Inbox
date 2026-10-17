class Whatsapp::CampaignStatusService
  pattr_initialize [:inbox!]

  def perform(statuses)
    Array(statuses).each do |status|
      next if status[:id].blank?

      recipient = find_recipient(status)
      next unless recipient

      recipient.with_lock do
        next if recipient.provider_message_id.present? && recipient.provider_message_id != status[:id]

        recipient.update!(provider_message_id: status[:id])
        recipient.reconcile!(status)
      end
    end
  end

  private

  def find_recipient(status)
    scope = CampaignRecipient.joins(:campaign).where(campaigns: { inbox_id: inbox.id, account_id: inbox.account_id })
    recipient = scope.find_by(provider_message_id: status[:id])
    return recipient if recipient || !status[:biz_opaque_callback_data].to_s.match?(/\Acampaign_recipient:\d+\z/)

    scope.find_by(id: status[:biz_opaque_callback_data].split(':').last, state: %w[sending unknown])
  end
end

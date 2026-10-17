class Campaigns::RecoverJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Campaign.where(campaign_status: :processing).where.not(audience_snapshotted_at: nil).find_each do |campaign|
      campaign.enqueue_dispatch if campaign.inbox.inbox_type == 'Whatsapp'
    end
  end
end

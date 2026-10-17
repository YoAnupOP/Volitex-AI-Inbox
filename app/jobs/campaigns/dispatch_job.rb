class Campaigns::DispatchJob < ApplicationJob
  queue_as :campaigns

  def perform(campaign, token)
    return unless campaign.reload.campaign_dispatch_enabled? && campaign.dispatch_token == token

    Whatsapp::CampaignDispatchService.new(campaign: campaign).perform
    next_token = campaign.with_lock do
      next unless campaign.processing? && campaign.dispatch_token == token

      value = SecureRandom.uuid
      campaign.update!(dispatch_token: value, dispatch_scheduled_at: Time.current)
      value
    end
    self.class.set(wait: 1.second).perform_later(campaign, next_token) if next_token
  end
end

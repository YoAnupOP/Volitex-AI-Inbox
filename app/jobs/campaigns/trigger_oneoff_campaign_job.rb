class Campaigns::TriggerOneoffCampaignJob < ApplicationJob
  queue_as { arguments.first.inbox.inbox_type == 'Whatsapp' ? :campaigns : :low }

  def perform(campaign)
    campaign.trigger!
  end
end

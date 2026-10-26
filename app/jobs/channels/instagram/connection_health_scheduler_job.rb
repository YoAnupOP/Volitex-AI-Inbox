class Channels::Instagram::ConnectionHealthSchedulerJob < ApplicationJob
  queue_as :low

  def perform
    Channel::Instagram.joins(:account).merge(Account.active)
                      .where('expires_at <= :expiry OR subscription_verified_at IS NULL OR subscription_verified_at <= :checked',
                             expiry: 10.days.from_now, checked: 1.day.ago).find_each do |channel|
      Channels::Instagram::ConnectionHealthJob.perform_later(channel)
    end
  end
end

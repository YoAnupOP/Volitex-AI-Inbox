# == Schema Information
#
# Table name: channel_instagram
#
#  id           :bigint           not null, primary key
#  access_token :string           not null
#  expires_at   :datetime         not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#  instagram_id :string           not null
#
# Indexes
#
#  index_channel_instagram_on_instagram_id  (instagram_id) UNIQUE
#
class Channel::Instagram < ApplicationRecord
  include Channelable
  include Reauthorizable
  self.table_name = 'channel_instagram'

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  encrypts :access_token if Chatwoot.encryption_configured?

  AUTHORIZATION_ERROR_THRESHOLD = 1
  HTTP_OPEN_TIMEOUT = 5
  HTTP_READ_TIMEOUT = 15
  SUBSCRIBED_FIELDS = %w[messages message_reactions messaging_seen messaging_postbacks comments].freeze

  validates :access_token, presence: true
  validates :instagram_id, uniqueness: true, presence: true

  before_save :stamp_token_issuance, if: :will_save_change_to_access_token?
  after_create_commit :schedule_connection_check
  before_destroy :unsubscribe

  def name
    'Instagram'
  end

  def create_contact_inbox(instagram_id, name)
    @contact_inbox = ::ContactInboxWithContactBuilder.new({
                                                            source_id: instagram_id,
                                                            inbox: inbox,
                                                            contact_attributes: { name: name }
                                                          }).perform
  end

  def subscribe(reauthorize: false)
    failure = nil
    with_lock do
      data = Instagram::GraphClient.new(self[:access_token]).request(:post, "#{instagram_id}/subscribed_apps",
                                                                     params: { subscribed_fields: SUBSCRIBED_FIELDS.join(',') })
      raise Instagram::GraphClient::Error.new(status: 502) unless data['success'] == true

      update!(subscription_verified_at: Time.current)
      reauthorized! if reauthorize
    rescue Instagram::GraphClient::Error => e
      prompt_reauthorization! if e.authorization_error? && !reauthorization_required?
      failure = e
    end
    raise failure if failure

    true
  end

  def unsubscribe
    HTTParty.delete(
      "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}/#{instagram_id}/subscribed_apps",
      query: {
        access_token: self[:access_token]
      },
      open_timeout: HTTP_OPEN_TIMEOUT,
      timeout: HTTP_READ_TIMEOUT
    )
    true
  rescue StandardError => e
    Rails.logger.warn("Instagram unsubscribe failed channel_id=#{id} error=#{e.class.name}")
    true
  end

  def valid_access_token
    Instagram::RefreshOauthTokenService.new(channel: self).access_token
  end

  def notify_connection_failure
    key = "instagram:connection_failure_notice:#{id}"
    return unless Redis::Alfred.set(key, true, nx: true, ex: 1.day.to_i)

    AdministratorNotifications::ChannelNotificationsMailer.with(account: account).instagram_connection_failure(inbox).deliver_later
  end

  def reject_invalid_token!(token)
    with_lock do
      authorization_error! if self[:access_token] == token && !reauthorization_required?
    end
  end

  private

  def stamp_token_issuance
    self.token_refreshed_at = Time.current
    self.subscription_verified_at = nil
  end

  def schedule_connection_check
    Channels::Instagram::ConnectionHealthJob.perform_later(self)
  end
end

# Handles Instagram comment webhook events.
# https://developers.facebook.com/docs/instagram-platform/webhooks#comments
#
# A comment event value looks like:
# {
#   "from": { "id": "<IG_USER_ID>", "username": "<USERNAME>" },
#   "media": { "id": "<MEDIA_ID>", "media_product_type": "FEED" },
#   "id": "<COMMENT_ID>",
#   "text": "<COMMENT_TEXT>",
#   "timestamp": "<ISO8601>"
# }
class Instagram::CommentsService < Instagram::WebhooksBaseService
  attr_reader :comment

  def initialize(comment, channel)
    @comment = comment
    super(channel)
  end

  def perform
    inbox_channel(channel.instagram_id)
    return if @inbox.blank?

    if @inbox.channel.reauthorization_required?
      Rails.logger.info("Skipping comment processing as reauthorization is required for inbox #{@inbox.id}")
      return
    end

    return if comment_already_processed?

    ensure_contact
    return if @contact_inbox.blank?

    create_comment_message
  end

  private

  def comment_already_processed?
    @inbox.messages.exists?(source_id: comment[:id])
  end

  def ensure_contact
    @contact_inbox = @inbox.contact_inboxes.find_by(source_id: commenter_id)

    if @contact_inbox.blank?
      user = fetch_commenter_profile
      # Ensure name is never blank — fall back to username, then to a readable placeholder
      user['name'] = user['name'].presence || user['username'].presence || "IG User #{commenter_id}"
      find_or_create_contact(user)
    else
      @contact = @contact_inbox.contact
    end
  end

  def commenter_id
    comment.dig(:from, :id)
  end

  def fetch_commenter_profile
    fields = 'name,username,profile_pic'
    url = "#{base_uri}/#{commenter_id}?fields=#{fields}&access_token=#{@inbox.channel.access_token}"
    response = HTTParty.get(url)

    if response.success?
      result = JSON.parse(response.body).with_indifferent_access
      return {
        'name' => result['name'] || result['username'],
        'username' => result['username'],
        'profile_pic' => result['profile_pic'],
        'id' => result['id']
      }.with_indifferent_access
    end

    # Fallback: build a minimal profile from the webhook payload itself
    {
      'name' => comment.dig(:from, :username) || "Unknown (IG: #{commenter_id})",
      'username' => comment.dig(:from, :username),
      'id' => commenter_id
    }.with_indifferent_access
  end

  def create_comment_message
    conversation = find_or_create_conversation

    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :incoming,
      status: :sent,
      source_id: comment[:id],
      content: comment[:text],
      sender: @contact,
      content_attributes: {
        instagram_comment: true,
        comment_id: comment[:id],
        media_id: comment.dig(:media, :id),
        media_product_type: comment.dig(:media, :media_product_type)
      }
    )
  end

  def find_or_create_conversation
    scope = Conversation.where(account_id: @inbox.account_id, inbox_id: @inbox.id, contact_id: @contact.id)

    if @inbox.lock_to_single_conversation
      scope.order(created_at: :desc).first || build_conversation
    else
      scope.where.not(status: :resolved).order(created_at: :desc).first || build_conversation
    end
  end

  def build_conversation
    Conversation.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    )
  end

  def base_uri
    "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"
  end
end

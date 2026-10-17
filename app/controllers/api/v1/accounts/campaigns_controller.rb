class Api::V1::Accounts::CampaignsController < Api::V1::Accounts::BaseController
  before_action :campaign, except: [:index, :create]
  before_action :check_authorization

  def index
    @campaigns = Current.account.campaigns
  end

  def show; end

  def create
    @campaign = Current.account.campaigns.create!(campaign_params)
  end

  def update
    @campaign.update!(campaign_params)
  end

  def destroy
    reject_campaign!('Delivery history is retained; cancel the campaign instead') if @campaign.audience_snapshotted_at?

    @campaign.destroy!
    head :ok
  end

  def pause
    reject_campaign!('Legacy processing campaign requires operator review') if @campaign.processing? && !@campaign.audience_snapshotted_at?

    transition_campaign(:paused, %w[active processing])
    render :show
  end

  def resume
    transition_campaign(@campaign.audience_snapshotted_at? ? :processing : :active, ['paused'])
    @campaign.trigger! if @campaign.active? && @campaign.scheduled_at <= Time.current
    @campaign.enqueue_dispatch if @campaign.processing?
    render :show
  end

  def cancel
    transition_campaign(:cancelled, %w[active processing paused])
    @campaign.campaign_recipients.where(state: %w[pending retryable]).update_all(state: 'cancelled', updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations -- atomic terminal transition; constrained in PostgreSQL
    render :show
  end

  def recipients
    render json: @campaign.campaign_recipients.order(:id).where('id > ?', params[:after_id].to_i).limit(100)
                          .select(:id, :contact_id, :state, :attempts, :provider_message_id, :error_code, :updated_at)
  end

  private

  def transition_campaign(state, from)
    @campaign.with_lock do
      unless @campaign.inbox.inbox_type == 'Whatsapp' && from.include?(@campaign.campaign_status)
        reject_campaign!('Invalid WhatsApp campaign transition')
      end

      @campaign.update!(campaign_status: state, dispatch_token: nil, dispatch_scheduled_at: nil)
    end
  end

  def reject_campaign!(message)
    @campaign.errors.add(:base, message)
    raise ActiveRecord::RecordInvalid, @campaign
  end

  def campaign
    @campaign ||= Current.account.campaigns.find_by!(display_id: params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:title, :description, :message, :enabled, :trigger_only_during_business_hours, :inbox_id, :sender_id,
                                     :scheduled_at, audience: [:type, :id], trigger_rules: {}, template_params: {})
  end
end

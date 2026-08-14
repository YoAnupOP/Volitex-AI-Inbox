class Api::V1::Accounts::Instagram::CommentsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_inbox

  def media
    render json: comments_client.media(after: params[:after])
  rescue Instagram::CommentsClient::RequestError => e
    render_instagram_error(e)
  end

  def index
    render json: comments_client.comments(params[:media_id], after: params[:after])
  rescue Instagram::CommentsClient::RequestError => e
    render_instagram_error(e)
  end

  def create
    render json: comments_client.create_comment(params[:media_id], comment_params[:message]), status: :created
  rescue Instagram::CommentsClient::RequestError => e
    render_instagram_error(e)
  end

  def reply
    render json: comments_client.reply(params[:id], comment_params[:message]), status: :created
  rescue Instagram::CommentsClient::RequestError => e
    render_instagram_error(e)
  end

  def update
    render json: comments_client.update_visibility(params[:id], hidden: ActiveModel::Type::Boolean.new.cast(params[:hide]))
  rescue Instagram::CommentsClient::RequestError => e
    render_instagram_error(e)
  end

  def destroy
    comments_client.delete(params[:id])
    head :no_content
  rescue Instagram::CommentsClient::RequestError => e
    render_instagram_error(e)
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :show?
    return if @inbox.channel.is_a?(Channel::Instagram)

    render json: { message: 'Comments Manager is available only for Instagram Login inboxes.' }, status: :unprocessable_entity
  end

  def comments_client
    @comments_client ||= Instagram::CommentsClient.new(@inbox.channel)
  end

  def comment_params
    params.permit(:message)
  end

  def render_instagram_error(error)
    response.set_header('Retry-After', error.retry_after) if error.retry_after.present?
    render json: { message: error.message, retry_after: error.retry_after }, status: error.status
  end
end

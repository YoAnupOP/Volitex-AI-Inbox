class Webhooks::MetaController < ActionController::Base
  skip_forgery_protection
  before_action :verify_signed_request
  skip_before_action :verify_signed_request, only: :data_deletion_status

  def deauthorize
    user_id = parse_signed_request(params[:signed_request])
    return render json: { error: 'Invalid request' }, status: :bad_request unless user_id

    deactivate_channels(user_id)
    render json: { success: true }
  end

  def data_deletion
    user_id = parse_signed_request(params[:signed_request])
    return render json: { error: 'Invalid request' }, status: :bad_request unless user_id

    confirmation_code = SecureRandom.hex(10)
    schedule_data_deletion(user_id, confirmation_code)

    render json: {
      url: "#{ENV.fetch('FRONTEND_URL', 'https://inbox.volitexai.tech')}/data-deletion/#{confirmation_code}",
      confirmation_code: confirmation_code
    }
  end

  def data_deletion_status
    deletion_request = MetaDataDeletionRequest.find_by(confirmation_code: params[:confirmation_code])
    return render json: { error: 'Not found' }, status: :not_found unless deletion_request

    render json: {
      confirmation_code: deletion_request.confirmation_code,
      status: deletion_request.status,
      requested_at: deletion_request.requested_at,
      completed_at: deletion_request.completed_at
    }
  end

  private

  def verify_signed_request
    return if params[:signed_request].present?

    render json: { error: 'Missing signed_request' }, status: :bad_request
  end

  def parse_signed_request(signed_request)
    encoded_sig, payload = signed_request.split('.', 2)
    return nil unless encoded_sig && payload

    # Decode the payload
    decoded_payload = Base64.urlsafe_decode64(payload)
    data = JSON.parse(decoded_payload)

    # Verify signature
    app_secret = GlobalConfigService.load('META_APP_SECRET', nil)
    return nil unless app_secret

    expected_sig = OpenSSL::HMAC.digest(
      OpenSSL::Digest.new('sha256'),
      app_secret,
      payload
    )

    return nil unless ActiveSupport::SecurityUtils.secure_compare(
      Base64.urlsafe_decode64(encoded_sig),
      expected_sig
    )

    data['user_id']
  rescue JSON::ParserError, ArgumentError
    nil
  end

  def deactivate_channels(user_id)
    channels = Channel::Whatsapp.where("provider_config->>'user_id' = ?", user_id).to_a
    channels += Channel::Instagram.where(instagram_id: user_id).to_a
    channels.each { |channel| channel.inbox&.destroy! }

    Rails.logger.info "Deactivated channels for Meta user_id: #{user_id}"
  end

  def schedule_data_deletion(user_id, confirmation_code)
    # Store deletion request for processing
    MetaDataDeletionRequest.create!(
      user_id: user_id,
      confirmation_code: confirmation_code,
      status: 'pending',
      requested_at: Time.current
    )

    # Enqueue job to process deletion
    MetaDataDeletionJob.perform_later(user_id, confirmation_code)

    Rails.logger.info "Scheduled data deletion for Meta user_id: #{user_id}, confirmation: #{confirmation_code}"
  end
end

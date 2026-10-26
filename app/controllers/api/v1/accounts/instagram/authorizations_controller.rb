class Api::V1::Accounts::Instagram::AuthorizationsController < Api::V1::Accounts::OauthAuthorizationController
  include InstagramConcern
  include Instagram::IntegrationHelper

  def create
    # https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/business-login#step-1--get-authorization
    redirect_url = instagram_client.auth_code.authorize_url(
      {
        redirect_uri: "#{base_url}/instagram/callback",
        scope: REQUIRED_SCOPES.join(','),
        enable_fb_login: 'false',
        force_reauth: 'true',
        response_type: 'code',
        state: instagram_authorization_state
      }
    )
    if redirect_url
      render json: { success: true, url: redirect_url }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  private

  def instagram_authorization_state
    inbox = Current.account.inboxes.find(params[:inbox_id]) if params[:inbox_id].present?
    raise Pundit::NotAuthorizedError if inbox && !inbox.channel.is_a?(Channel::Instagram)

    generate_instagram_token(Current.account.id, params[:return_to], user_id: Current.user.id,
                                                                     browser_nonce: instagram_browser_nonce, inbox_id: inbox&.id)
  end

  def instagram_browser_nonce
    cookies.encrypted[:instagram_oauth_session] ||= {
      value: SecureRandom.urlsafe_base64(32), httponly: true, same_site: :lax,
      secure: URI.parse(base_url).scheme == 'https', expires: 1.hour.from_now
    }
    cookies.encrypted[:instagram_oauth_session]
  end
end

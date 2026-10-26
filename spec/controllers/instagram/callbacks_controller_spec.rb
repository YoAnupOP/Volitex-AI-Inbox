require 'rails_helper'

RSpec.describe Instagram::CallbacksController do
  let(:account) { create(:account) }
  let(:valid_params) { { code: 'valid_code', state: "#{account.id}|valid_token" } }
  let(:error_params) { { error: 'access_denied', error_description: 'User denied access', state: "#{account.id}|valid_token" } }
  let(:oauth_client) { instance_double(OAuth2::Client) }
  let(:auth_code_object) { instance_double(OAuth2::Strategy::AuthCode) }
  let(:access_token) do
    instance_double(OAuth2::AccessToken, token: 'test_token', params: { 'permissions' => Instagram::IntegrationHelper::REQUIRED_SCOPES.join(',') })
  end
  let(:long_lived_token_response) { { 'access_token' => 'long_lived_test_token', 'expires_in' => 5_184_000 } }
  let(:user_details) { { 'username' => 'test_user', 'user_id' => '12345' } }
  let(:exception_tracker) { instance_double(ChatwootExceptionTracker) }

  before do
    allow(controller).to receive(:consume_instagram_state!).and_return('sub' => account.id, 'inbox_id' => nil)
    allow(controller).to receive(:instagram_client).and_return(oauth_client)
    allow(controller).to receive(:base_url).and_return('https://app.chatwoot.com')
    allow(controller).to receive(:account).and_return(account)
    allow(oauth_client).to receive(:auth_code).and_return(auth_code_object)
    allow(controller).to receive(:exchange_for_long_lived_token).and_return(long_lived_token_response)
    allow(controller).to receive(:fetch_instagram_user_details).and_return(user_details)
    allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
    allow(exception_tracker).to receive(:capture_exception)

    stub_request(:post, 'https://graph.instagram.com/v22.0/12345/subscribed_apps')
      .with(query: { access_token: 'long_lived_test_token',
                     subscribed_fields: 'messages,message_reactions,messaging_seen,messaging_postbacks,comments' })
      .to_return(status: 200, body: { success: true }.to_json)
  end

  describe '#show' do
    context 'when authorization is successful' do
      before do
        allow(auth_code_object).to receive(:get_token).and_return(access_token)
      end

      it 'creates instagram channel and inbox' do
        expect do
          get :show, params: valid_params
        end.to change(Channel::Instagram, :count).by(1).and change(Inbox, :count).by(1)

        expect(Channel::Instagram.last.access_token).to eq('long_lived_test_token')
        expect(Channel::Instagram.last.instagram_id).to eq('12345')
        expect(Inbox.last.name).to eq('test_user')

        expect(Inbox.last.channel.reauthorization_required?).to be false
        expect(response).to redirect_to(app_instagram_inbox_agents_url(account_id: account.id, inbox_id: Inbox.last.id))
      end

      it 'updates existing channel with new token' do
        # Create an existing channel
        existing_channel = create(:channel_instagram, account: account, instagram_id: '12345', access_token: 'old_token')
        create(:inbox, channel: existing_channel, account: account, name: 'old_username')

        expect do
          get :show, params: valid_params
        end.to not_change(Channel::Instagram, :count).and not_change(Inbox, :count)

        existing_channel.reload
        expect(existing_channel.access_token).to eq('long_lived_test_token')
        expect(existing_channel.instagram_id).to eq('12345')
        expect(existing_channel.reauthorization_required?).to be false
      end
    end

    context 'when subscription fails' do
      before do
        allow(auth_code_object).to receive(:get_token).and_return(access_token)
        stub_request(:post, %r{12345/subscribed_apps}).to_return(status: 503, body: '{}')
      end

      it 'retains the inbox but marks it for repair and schedules recovery' do
        expect { get :show, params: valid_params }.to have_enqueued_job(Channels::Instagram::ConnectionHealthJob).at_least(:once)
        channel = Channel::Instagram.last
        expect(channel.subscription_verified_at).to be_nil
        expect(channel).to be_reauthorization_required
        expect(response.location).to include('error_type')
      end
    end

    context 'when repairing a specified inbox' do
      let(:original) { create(:channel_instagram, account: account, instagram_id: 'original-id') }

      before do
        allow(auth_code_object).to receive(:get_token).and_return(access_token)
        allow(controller).to receive(:consume_instagram_state!).and_return('sub' => account.id, 'inbox_id' => original.inbox.id)
      end

      it 'rejects a different Instagram identity without creating a replacement inbox' do
        original
        expect { get :show, params: valid_params }.not_to change(Channel::Instagram, :count)
        expect(original.reload[:access_token]).not_to eq('long_lived_test_token')
        expect(response.location).to include('error_type')
      end
    end

    context 'when permission grants are incomplete' do
      before do
        allow(auth_code_object).to receive(:get_token).and_return(access_token)
        allow(access_token).to receive(:params).and_return('permissions' => 'instagram_business_basic')
      end

      it 'does not provision an apparently connected inbox' do
        expect { get :show, params: valid_params }.not_to change(Channel::Instagram, :count)
        expect(response.location).to include('error_type')
      end
    end

    context 'when state is invalid' do
      it 'rejects the callback before exchanging the authorization code' do
        allow(controller).to receive(:consume_instagram_state!).and_raise(Instagram::IntegrationHelper::InvalidState)
        expect(auth_code_object).not_to receive(:get_token)
        get :show, params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user denies authorization'  do
      it 'redirects to error page with authorization error details' do
        get :show, params: error_params

        expect(response).to redirect_to(
          app_new_instagram_inbox_url(
            account_id: account.id,
            error_type: 'access_denied',
            code: 400,
            error_message: 'User denied access'
          )
        )
      end
    end

    context 'when an OAuth error occurs' do
      before do
        oauth_error = OAuth2::Error.new(
          OpenStruct.new(
            body: { error_type: 'OAuthException', code: 400, error_message: 'Invalid OAuth code' }.to_json,
            status: 400
          )
        )
        allow(auth_code_object).to receive(:get_token).and_raise(oauth_error)
      end

      it 'handles OAuth errors and redirects to error page' do
        get :show, params: valid_params

        expected_url = app_new_instagram_inbox_url(
          account_id: account.id,
          error_type: 'OAuth2::Error',
          code: 400,
          error_message: 'Instagram connection could not be verified. Please retry connecting the original account.'
        )
        expect(response).to redirect_to(expected_url)
      end
    end

    context 'when a standard error occurs' do
      before do
        allow(auth_code_object).to receive(:get_token).and_raise(StandardError.new('Unknown error'))
      end

      it 'handles standard errors and redirects to error page' do
        get :show, params: valid_params

        expected_url = app_new_instagram_inbox_url(
          account_id: account.id,
          error_type: 'StandardError',
          code: 400,
          error_message: 'Instagram connection could not be verified. Please retry connecting the original account.'
        )
        expect(response).to redirect_to(expected_url)
      end
    end
  end
end

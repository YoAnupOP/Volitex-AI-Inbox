require 'rails_helper'

RSpec.describe 'Super Admin account provisioning', type: :request do
  let(:super_admin) { create(:super_admin) }

  before do
    InstallationConfig.where(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').destroy_all
  end

  it 'applies shipped defaults without changing existing accounts or granting membership' do
    existing = create(:account)
    existing.disable_features!(:agent_bots)
    original_flags = existing.reload.selected_feature_flags
    sign_in(super_admin, scope: :super_admin)

    expect { post '/super_admin/accounts', params: { account: { name: 'Provisioned tenant', locale: 'en' } } }
      .to change(Account, :count).by(1)

    expect(response).to have_http_status(:redirect)
    provisioned = Account.find_by!(name: 'Provisioned tenant')
    expected = Featurable::FEATURE_LIST.select { |feature| feature['enabled'] }.pluck('name')
    expect(provisioned.enabled_features.keys).to match_array(expected)
    expect(provisioned.feature_enabled?('whatsapp_campaign')).to be(true)
    expect(provisioned.account_users).to be_empty
    expect(provisioned.captain_models).to be_nil
    expect(existing.reload.selected_feature_flags).to eq(original_flags)
  end

  it 'renders shipped defaults and limits on the OSS new-account form' do
    sign_in(super_admin, scope: :super_admin)

    get '/super_admin/accounts/new'

    expect(response).to have_http_status(:ok)
    form = Nokogiri::HTML(response.body)
    expect(form.at_css('#enabled_features_feature_whatsapp_campaign')['checked']).to be_present
    expect(form.at_css('#account_limits_agents')).to be_present
    expect(form.at_css('#account_limits_emails')).to be_present
  end

  it 'uses shipped defaults for model provisioning without an installation override' do
    expect(create(:account).feature_enabled?('whatsapp_campaign')).to be(true)
  end

  it 'uses installation overrides on the form without re-enabling disabled defaults' do
    InstallationConfig.create!(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS', value: [{ name: 'whatsapp_campaign', enabled: false }])
    sign_in(super_admin, scope: :super_admin)

    get '/super_admin/accounts/new'

    expect(Nokogiri::HTML(response.body).at_css('#enabled_features_feature_whatsapp_campaign')['checked']).to be_nil
  end

  it 'persists explicit create choices instead of adding installation defaults' do
    InstallationConfig.create!(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS', value: [{ name: 'agent_bots', enabled: true }])
    sign_in(super_admin, scope: :super_admin)

    post '/super_admin/accounts', params: {
      account: { name: 'Explicit tenant', locale: 'en' },
      enabled_features: { _present: '1', feature_whatsapp_campaign: '1', feature_agent_bots: '0' }
    }

    expect(response).to have_http_status(:redirect)
    expect(Account.find_by!(name: 'Explicit tenant').enabled_features.keys).to contain_exactly('whatsapp_campaign')
  end

  it 'allows creating an account with all features unchecked' do
    sign_in(super_admin, scope: :super_admin)

    post '/super_admin/accounts', params: {
      account: { name: 'No features', locale: 'en' }, enabled_features: { _present: '1' }
    }

    expect(response).to have_http_status(:redirect)
    expect(Account.find_by!(name: 'No features').enabled_features).to be_empty
  end

  it 'renders, updates and shows flags across both bitset columns and stores supported limits in OSS' do
    account = create(:account)
    sign_in(super_admin, scope: :super_admin)

    get "/super_admin/accounts/#{account.id}/edit"

    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).at_css('#enabled_features_feature_whatsapp_campaign')['checked']).to be_present

    put "/super_admin/accounts/#{account.id}", params: {
      account: { name: account.name, limits: { agents: '5', inboxes: '', emails: '0', unsupported: '999' } },
      enabled_features: { _present: '1', feature_whatsapp_campaign: '1', feature_api_and_webhooks: '1', feature_unknown: '1' }
    }

    expect(response).to have_http_status(:redirect)
    expect(account.reload.enabled_features.keys).to contain_exactly('whatsapp_campaign', 'api_and_webhooks')
    expect(account.limits).to eq('agents' => '5', 'emails' => '0')

    get "/super_admin/accounts/#{account.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('WhatsApp Campaign', 'Active', 'Inactive', 'Agents')
  end

  it 'clears all flags when the edit form is submitted without checked features' do
    account = create(:account)
    sign_in(super_admin, scope: :super_admin)

    put "/super_admin/accounts/#{account.id}", params: {
      account: { name: account.name }, enabled_features: { _present: '1' }
    }

    expect(response).to have_http_status(:redirect)
    expect(account.reload.enabled_features).to be_empty
  end

  it 'preserves feature flags when unrelated account attributes are updated' do
    account = create(:account)
    original_flags = account.selected_feature_flags
    sign_in(super_admin, scope: :super_admin)

    put "/super_admin/accounts/#{account.id}", params: { account: { name: 'Renamed tenant' } }

    expect(response).to have_http_status(:redirect)
    expect(account.reload.selected_feature_flags).to eq(original_flags)
  end

  it 'respects installation overrides including disabled defaults' do
    InstallationConfig.create!(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS', value: [{ name: 'agent_bots', enabled: false }])
    sign_in(super_admin, scope: :super_admin)

    post '/super_admin/accounts', params: { account: { name: 'Restricted tenant', locale: 'en' } }

    expect(response).to have_http_status(:redirect)
    expect(Account.find_by!(name: 'Restricted tenant').enabled_features).to be_empty
  end

  it 'does not allow an account administrator to provision another tenant' do
    user = create(:user)
    create(:account_user, user: user, role: :administrator)
    sign_in(user)

    expect { post '/super_admin/accounts', params: { account: { name: 'Unauthorized tenant' } } }
      .not_to change(Account, :count)
    expect(response).to have_http_status(:redirect)
  end

  it 'does not allow unauthenticated provisioning' do
    expect { post '/super_admin/accounts', params: { account: { name: 'Unauthorized tenant' } } }
      .not_to change(Account, :count)
    expect(response).to have_http_status(:redirect)
  end
end

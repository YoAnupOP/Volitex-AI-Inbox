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
    expect(provisioned.account_users).to be_empty
    expect(provisioned.captain_models).to be_nil
    expect(existing.reload.selected_feature_flags).to eq(original_flags)
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

require 'rails_helper'

RSpec.describe 'Quick Menus API', type: :request do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }
  let(:menu) { create(:quick_menu, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:base_path) { "/api/v1/accounts/#{account.id}/quick_menus" }

  it 'allows an agent to list and read account menus' do
    menu
    get base_path, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.pluck('id')).to contain_exactly(menu.id)

    get "#{base_path}/#{menu.id}", headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body['id']).to eq(menu.id)
  end

  it 'restricts agent mutations and scopes all IDs to the current account' do
    post base_path, params: { quick_menu: { name: 'Other', body: 'Body', items: [{ title: 'Yes' }] } },
                    headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)

    other_menu = create(:quick_menu, account: other_account)
    get "#{base_path}/#{other_menu.id}", headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:not_found)

    patch "#{base_path}/#{other_menu.id}", params: { quick_menu: { name: 'Changed' } },
                                           headers: administrator.create_new_auth_token, as: :json
    expect(response).to have_http_status(:not_found)
    delete "#{base_path}/#{other_menu.id}", headers: administrator.create_new_auth_token, as: :json
    expect(response).to have_http_status(:not_found)
  end

  it 'allows account administrators to create, update, and delete menus' do
    payload = { quick_menu: { name: 'Returns', body: 'Choose', items: [{ title: 'Start return' }] } }
    post base_path, params: payload, headers: administrator.create_new_auth_token, as: :json
    expect(response).to have_http_status(:created)
    created_id = response.parsed_body['id']

    patch "#{base_path}/#{created_id}", params: { quick_menu: { name: 'Returns desk' } },
                                        headers: administrator.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body['name']).to eq('Returns desk')

    delete "#{base_path}/#{created_id}", headers: administrator.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    expect(account.quick_menus.exists?(created_id)).to be(false)
  end

  it 'rejects malformed item shapes without silently removing unexpected keys' do
    [[{ title: 'Help', value: 'unexpected' }], ['Help'], { title: 'Help' }, nil].each do |items|
      post base_path, params: { quick_menu: { name: 'Support', body: 'Choose', items: items } },
                      headers: administrator.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
    expect(account.quick_menus.count).to eq(0)
  end

  it 'rejects agent updates and deletes and unaffiliated account requests' do
    patch "#{base_path}/#{menu.id}", params: { quick_menu: { name: 'Changed' } },
                                     headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
    delete "#{base_path}/#{menu.id}", headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
    get "/api/v1/accounts/#{other_account.id}/quick_menus", headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(menu.reload.name).to eq('Support options')
  end
end

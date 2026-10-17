require 'rails_helper'

RSpec.describe 'Super Admin', type: :request do
  describe '/super_admin' do
    it 'renders the login page' do
      with_modified_env LOGRAGE_ENABLED: 'true' do
        get '/super_admin/sign_in'
        expect(response).to have_http_status(:ok)
        page = Nokogiri::HTML(response.body)
        expect(page.at_css('html')['class']).to include('admin-auth')
        expect(page.at_css('form')['action']).to eq('/super_admin/sign_in')
        expect(page.at_css('label[for="super_admin_email"]')).to be_present
        expect(page.at_css('input#super_admin_email')['autocomplete']).to eq('email')
        expect(page.at_css('label[for="super_admin_password"]')).to be_present
        expect(page.at_css('input#super_admin_password')['autocomplete']).to eq('current-password')
      end
    end
  end
end

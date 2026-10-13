require 'rails_helper'

RSpec.describe User do
  let(:user) { create(:user, confirmed_at: Time.current) }

  it 'keeps the confirmation token paired with the pending email across stale concurrent updates' do
    user.update!(email: 'controlled@example.com')
    first_request = described_class.find(user.id)
    second_request = described_class.find(user.id)

    first_request.update!(email: 'victim@example.com')
    second_request.update!(email: 'controlled@example.com')

    expect(user.reload.unconfirmed_email).to eq('controlled@example.com')
    expect(second_request.confirmation_token).to be_present
    expect(user.confirmation_token).to eq(second_request.confirmation_token)
  end

  it 'does not enable the vulnerable timeoutable redirect path on authentication models' do
    expect(described_class.devise_modules).not_to include(:timeoutable)
    expect(SuperAdmin.devise_modules).not_to include(:timeoutable)
  end
end

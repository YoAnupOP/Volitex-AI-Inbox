require 'rails_helper'

RSpec.describe QuickMenuPolicy do
  let(:account) { create(:account) }
  let(:menu) { create(:quick_menu, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:administrator) { create(:user, account: account, role: :administrator) }

  it 'allows account agents to list and read menus but not mutate them' do
    account_user = agent.account_users.find_by!(account: account)
    policy = described_class.new({ user: agent, account: account, account_user: account_user }, menu)

    expect(policy.index?).to be(true)
    expect(policy.show?).to be(true)
    expect(policy.create?).to be(false)
    expect(policy.update?).to be(false)
    expect(policy.destroy?).to be(false)
  end

  it 'allows account administrators to mutate menus' do
    account_user = administrator.account_users.find_by!(account: account)
    policy = described_class.new({ user: administrator, account: account, account_user: account_user }, menu)

    expect(policy.create?).to be(true)
    expect(policy.update?).to be(true)
    expect(policy.destroy?).to be(true)
  end

  it 'does not allow an agent to read a menu from another account' do
    other_account = create(:account)
    other_menu = create(:quick_menu, account: other_account)
    account_user = agent.account_users.find_by!(account: account)
    policy = described_class.new({ user: agent, account: account, account_user: account_user }, other_menu)

    expect(policy.show?).to be(false)
  end
end

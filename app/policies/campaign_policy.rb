class CampaignPolicy < ApplicationPolicy
  def index?
    @account_user&.administrator?
  end

  def update?
    @account_user&.administrator?
  end

  def show?
    @account_user&.administrator?
  end

  def create?
    @account_user&.administrator?
  end

  alias pause? update?
  alias resume? update?
  alias cancel? update?
  alias recipients? show?

  def destroy?
    @account_user&.administrator?
  end
end

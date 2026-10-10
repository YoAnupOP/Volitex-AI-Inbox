class Api::V1::Accounts::QuickMenusController < Api::V1::Accounts::BaseController
  before_action :set_quick_menu, only: [:show, :update, :destroy]

  def index
    authorize QuickMenu, :index?
    render json: Current.account.quick_menus.order(:name)
  end

  def show
    authorize @quick_menu, :show?
    render json: @quick_menu
  end

  def create
    @quick_menu = Current.account.quick_menus.new(quick_menu_params)
    authorize @quick_menu, :create?
    @quick_menu.save!
    render json: @quick_menu, status: :created
  end

  def update
    authorize @quick_menu, :update?
    @quick_menu.update!(quick_menu_params)
    render json: @quick_menu
  end

  def destroy
    authorize @quick_menu, :destroy?
    @quick_menu.destroy!
    head :ok
  end

  private

  def set_quick_menu
    @quick_menu = Current.account.quick_menus.find(params[:id])
  end

  def quick_menu_params
    params.require(:quick_menu).permit(:name, :body, items: [:title])
  end
end

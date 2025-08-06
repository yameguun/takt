class Admin::Company::UsersController < Admin::ApplicationController
  before_action :set_company
  before_action :set_user, only: %i[edit update]

  def index
    @users = @company.users.order(created_at: :desc).page(params[:page])
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_company_users_path(@company), flash: {success: "更新しました"}
    else
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:company_id, :department_id, :name)
  end

  def set_company
    @company = Company.find(params[:company_id])
  end

  def set_user
    @user = @company.users.find(params[:id])
  end
end

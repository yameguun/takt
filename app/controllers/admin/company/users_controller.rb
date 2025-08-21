# app/controllers/admin/company/users_controller.rb
class Admin::Company::UsersController < Admin::ApplicationController
  before_action :set_company
  before_action :set_user, only: %i[edit update remove_avatar destroy]

  def index
    @users = @company.users.kept.order(created_at: :desc).page(params[:page])
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

  def destroy
    @user.discard!
    redirect_to admin_company_users_path(@company), flash: {error: "削除しました"}, status: :see_other
  end

  # 画像削除アクション
  def remove_avatar
    @user.avatar.purge
    redirect_to edit_admin_company_user_path(@company, @user), 
                flash: {success: "画像を削除しました"}
  end

  private

  def user_params
    params.require(:user).permit(:company_id, :department_id, :name, :unit_price, :permission, :avatar)
  end

  def set_company
    @company = Company.find(params[:company_id])
  end

  def set_user
    @user = @company.users.kept.find(params[:id])
  end
end

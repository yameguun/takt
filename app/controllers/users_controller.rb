# app/controllers/users_controller.rb
class UsersController < BaseController
  before_action :set_user

  def index
    # パスワード変更画面の表示
  end

  def update
    # 現在のパスワードが入力されている場合は検証
    if params[:current_password].present?
      unless @user.authenticate(params[:current_password])
        flash.now[:alert] = "現在のパスワードが正しくありません"
        render :index, status: :unprocessable_entity
        return
      end
    end

    # 新しいパスワードの更新
    if @user.update(password_params)
      flash[:notice] = @user.authentication.present? ? "パスワードを設定しました" : "パスワードを変更しました"
      redirect_to user_path
    else
      flash.now[:alert] = @user.authentication.present? ? "パスワードの設定に失敗しました" : "パスワードの変更に失敗しました"
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
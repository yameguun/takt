# app/controllers/users_controller.rb
class UsersController < BaseController
  before_action :set_user

  def index
    # パスワード変更画面の表示
  end

  def update
    # SNSログインユーザーかどうかで処理を分岐
    if @user.authentication.present?
      # SNSログインユーザーの場合は現在のパスワード確認をスキップ
      if params[:user][:password].present?
        if @user.update(password_params)
          flash[:notice] = "パスワードを設定しました"
          redirect_to user_path
        else
          flash.now[:alert] = "パスワードの設定に失敗しました"
          render :index, status: :unprocessable_entity
        end
      else
        flash.now[:alert] = "新しいパスワードを入力してください"
        render :index, status: :unprocessable_entity
      end
    else
      # 通常のパスワード認証ユーザーの場合
      unless @user.authenticate(params[:current_password])
        flash.now[:alert] = "現在のパスワードが正しくありません"
        render :index, status: :unprocessable_entity
        return
      end

      if @user.update(password_params)
        flash[:notice] = "パスワードを変更しました"
        redirect_to user_path
      else
        flash.now[:alert] = "パスワードの変更に失敗しました"
        render :index, status: :unprocessable_entity
      end
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
class SessionsController < ApplicationController

  def new
  end

  def create
    @user = User.find_by(email: params[:email])

    if @user&.authenticate(params[:password])
      reset_session
      session[:user_id] = @user.id
      flash.now[:success] = "ログインしました"
      redirect_to root_path
    else
      flash.now[:error] = "メールアドレスまたはパスワードが違います"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    flash.now[:success] = "ログアウトしました"
    redirect_to login_path
  end
end

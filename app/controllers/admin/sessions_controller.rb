class Admin::SessionsController < ApplicationController
  layout "admin"

  def new
  end

  def create
    @administrator = Administrator.find_by(email: params[:email])

    if @administrator&.authenticate(params[:password])
      reset_session
      session[:administrator_id] = @administrator.id
      flash.now[:success] = "ログインしました"
      redirect_to admin_root_path
    else
      flash.now[:error] = "メールアドレスまたはパスワードが違います"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:administrator_id)
    flash.now[:success] = "ログアウトしました"
    redirect_to admin_login_path
  end
end
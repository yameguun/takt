class BaseController < ApplicationController
  before_action :require_login

  private

  def require_login
    unless user_signed_in?
      redirect_to login_path, alert: "ログインしてください"
    end
  end

  def user_signed_in?
    !!current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  helper_method :current_user, :user_signed_in?
end

class Admin::ApplicationController < ApplicationController
  layout "admin"

  before_action :require_login

  private

  def require_login
    unless administrator_signed_in?
      redirect_to admin_login_path, alert: "ログインしてください"
    end
  end

  def administrator_signed_in?
    !!current_administrator
  end

  def current_administrator
    @current_administrator ||= Administrator.find_by(id: session[:administrator_id])
  end

  helper_method :current_administrator, :administrator_signed_in?
end

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern,
                if: -> { Rails.env.production? && request.format.html? }

  helper_method :current_user, :logged_in?

  private

  # 渡されたユーザーでログインする
  def log_in(user)
    session[:user_id] = user.id
  end

  # 現在のユーザーを返す
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # ログインしているか確認する
  def logged_in?
    current_user.present?
  end

  # ログアウトする
  def log_out
    reset_session
    @current_user = nil
  end
end

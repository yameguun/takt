class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern,
                if: -> { Rails.env.production? && request.format.html? }

  helper_method :current_user, :logged_in?, :current_company, :can_switch_company?, :accessible_companies

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

  # 現在操作対象の会社を取得
  def current_company
    return nil unless current_user

    # セッションに切り替え先会社IDがある場合はそれを優先
    if session[:current_company_id].present? && current_user.is_manager?
      Company.find_by(id: session[:current_company_id]) || current_user.company
    else
      current_user.company
    end
  end

  # 会社切り替え権限があるかチェック
  def can_switch_company?
    current_user&.is_manager?
  end

  # ユーザーがアクセス可能な会社一覧を取得
  def accessible_companies
    return Company.none unless current_user&.is_manager?

    case current_user.permission
    when 3 # システム管理者
      Company.all.order(:name)
    when 2 # 管理者
      Company.all.order(:name) # 必要に応じて制限を追加
    when 1 # マネージャー
      Company.where(id: current_user.company_id) # 自社のみ
    else
      Company.none
    end
  end
end

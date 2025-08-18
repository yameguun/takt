class BaseController < ApplicationController
  before_action :require_login
  before_action :daily_report_project_count

  def daily_report_project_count
    @daily_report_project_count = DailyReportProject
      .joins(daily_report: :user)
      .joins(project: :client)
      .where(is_overtime_approved: false)
      .where(is_overtime_requested: true)
      .where(users: { department_id: current_user.department_id }).count
  end

  private

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "ログインしてください"
    end
  end
end

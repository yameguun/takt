class OvertimeRequestsController < BaseController
  before_action :require_manager?

  def index
    # 残業申請中かつマネージャーと同じ部署であること
@daily_report_projects = DailyReportProject
    .select("daily_report_projects.*, clients.name AS client_name, projects.name AS project_name, users.name AS user_name")
    .joins(daily_report: :user)
    .joins(project: :client)
    .where(is_overtime_approved: 0)
    .where(is_overtime_requested: 1)
    .where(users: { department_id: current_user.department_id })
  end

  private

  def require_manager?
    unless current_user.is_manager?
      redirect_to root_path
    end
  end
end

class Manager::OvertimeRequestsController < BaseController
  before_action :require_manager
  before_action :set_daily_report_project, only: [:approve]

  def index
    # 残業申請中かつマネージャーと同じ部署であること
    @daily_report_projects = DailyReportProject
      .joins(daily_report: :user)
      .joins(project: :client)
      .where(is_overtime_approved: false)
      .where(is_overtime_requested: true)
      .where(users: { department_id: current_user.department_id })
      .includes(daily_report: :user, project: :client)
      .order('daily_reports.date DESC, users.name ASC')
  end

  def approve
    if @daily_report_project.update(is_overtime_approved: true)
      respond_to do |format|
        format.json { render json: { success: true, message: '残業申請を承認しました' }, status: :ok }
        format.html { redirect_to manager_overtime_requests_path, notice: '残業申請を承認しました' }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, message: '承認処理に失敗しました' }, status: :unprocessable_entity }
        format.html { redirect_to manager_overtime_requests_path, alert: '承認処理に失敗しました' }
      end
    end
  end

  private

  def set_daily_report_project
    @daily_report_project = DailyReportProject.find(params[:id])
    
    # セキュリティチェック：同じ部署の申請のみ承認可能
    unless @daily_report_project.daily_report.user.department_id == current_user.department_id
      respond_to do |format|
        format.json { render json: { success: false, message: '権限がありません' }, status: :forbidden }
        format.html { redirect_to manager_overtime_requests_path, alert: '権限がありません' }
      end
    end
  end

  def require_manager
    unless current_user&.is_manager?
      flash[:danger] = "この機能を利用する権限がありません"
      redirect_to root_path
    end
  end
end

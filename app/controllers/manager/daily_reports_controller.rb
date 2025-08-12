class Manager::DailyReportsController < BaseController
  before_action :require_manager
  before_action :set_target_date

  def index
    # N+1問題を回避した効率的なデータ取得
    @users = current_user.company.users
      .includes(:department)
      .order(:name)

    # 指定日の日報を効率的に取得（コメントも同時に取得）
    @reports_by_user_id = DailyReport
      .where(user_id: @users.select(:id), date: @target_date)
      .includes({ comments: :user }, daily_report_projects: { project: :client })
      .where.not(daily_report_projects: { description: nil })
      .index_by(&:user_id)

    @report_statistics = calculate_statistics
  end

  private

  def require_manager
    unless current_user&.is_manager?
      flash[:danger] = "この機能を利用する権限がありません"
      redirect_to root_path
    end
  end

  def set_target_date
    @target_date = begin
      Date.iso8601(params[:date]) if params[:date].present?
    rescue ArgumentError
      nil
    end || Time.zone.today
    
    @prev_date = @target_date - 1.day
    @next_date = @target_date + 1.day
  end

  def calculate_statistics
    reports_with_content = @reports_by_user_id.values
    
    # 作業時間と残業申請の集計
    minutes_scope = DailyReportProject
      .joins(:daily_report)
      .where(daily_reports: { user_id: @users.select(:id), date: @target_date })

    {
      submitted_count: reports_with_content.size,
      total_users: @users.size,
      submission_rate: @users.size.zero? ? 0 : ((reports_with_content.size.to_f / @users.size) * 100).round(1),
      total_work_hours: (minutes_scope.sum(:minutes) / 60.0).round(1),
      overtime_requests: minutes_scope.where(is_overtime_requested: true, is_overtime_approved: false).count
    }
  end
end
# app/controllers/manager/daily_reports_controller.rb
class Manager::DailyReportsController < BaseController
  before_action :require_manager
  before_action :set_target_date

  def index
    @users_with_reports = fetch_users_with_reports
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

  def fetch_users_with_reports
    # N+1問題を回避した効率的なクエリ
    current_user.company.users
      .includes(:department, daily_reports: { daily_report_projects: { project: :client } })
      .left_joins(:daily_reports)
      .where(daily_reports: { date: [@target_date, nil] })
      .select(
        'users.*',
        'daily_reports.id as report_id',
        'daily_reports.content as report_content',
        'daily_reports.date as report_date'
      )
      .order('users.name ASC')
      .group_by(&:id)
      .map { |_, users| users.first }
  end

  def calculate_statistics
    reports_with_content = @users_with_reports.select { |u| u.report_id.present? }
    total_users = current_user.company.users.count
    
    # 作業時間の集計
    total_minutes = DailyReportProject.joins(daily_report: :user)
      .where(users: { company_id: current_user.company_id })
      .where(daily_reports: { date: @target_date })
      .sum(:minutes)

    # 残業申請の集計
    overtime_requests = DailyReportProject.joins(daily_report: :user)
      .where(users: { company_id: current_user.company_id })
      .where(daily_reports: { date: @target_date })
      .where(is_overtime_requested: true, is_overtime_approved: false)
      .count

    {
      submitted_count: reports_with_content.count,
      total_users: total_users,
      submission_rate: total_users > 0 ? (reports_with_content.count.to_f / total_users * 100).round(1) : 0,
      total_work_hours: (total_minutes / 60.0).round(1),
      overtime_requests: overtime_requests
    }
  end
end

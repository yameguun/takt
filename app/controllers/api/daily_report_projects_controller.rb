class Api::DailyReportProjectsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_daily_report_project

  def request_overtime
    if @daily_report_project.update(is_overtime_requested: true)
      render json: { 
        success: true, 
        message: "作業 ##{params[:work_index]}の残業申請を送信しました",
        status: "pending"
      }
    else
      render json: { error: "残業申請の送信に失敗しました" }, status: :unprocessable_entity
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def cancel_overtime
    if @daily_report_project.update(is_overtime_requested: false)
      render json: { 
        success: true, 
        message: "作業 ##{params[:work_index]}の残業申請を取り消しました",
        status: "cancelled"
      }
    else
      render json: { error: "残業申請の取り消しに失敗しました" }, status: :unprocessable_entity
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_daily_report_project
    @daily_report = current_user.daily_reports.find_by!(date: params[:report_date])
    @daily_report_project = @daily_report.daily_report_projects.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "該当する作業記録が見つかりません" }, status: :not_found
  end
end

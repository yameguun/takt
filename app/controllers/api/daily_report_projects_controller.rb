# app/controllers/api/daily_report_projects_controller.rb
class Api::DailyReportProjectsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_daily_report_project

  def request_overtime
    if @daily_report_project.update(is_overtime_requested: true)
      send_overtime_request_notification(@daily_report_project, params[:work_index])
      
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
      send_overtime_cancel_notification(@daily_report_project, params[:work_index])
      
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

  def send_overtime_request_notification(work, work_index)
    return unless Rails.env.production?
    
    overtime_minutes = [work.minutes - 480, work.minutes].min
    overtime_hours = (overtime_minutes / 60.0).round(1)
    
    message = "#{current_user.name}さんが残業申請を提出しました"
    
    blocks = [
      {
        type: "header",
        text: {
          type: "plain_text",
          text: "⏰ 残業申請通知",
          emoji: true
        }
      },
      {
        type: "section",
        fields: [
          {
            type: "mrkdwn",
            text: "*申請者:*\n#{current_user.name}"
          },
          {
            type: "mrkdwn",
            text: "*日付:*\n#{@daily_report.date.strftime('%Y年%m月%d日')}"
          },
          {
            type: "mrkdwn",
            text: "*顧客/案件:*\n#{work.client.name} / #{work.project.name}"
          },
          {
            type: "mrkdwn",
            text: "*作業区分:*\n#{work.task_type.name}"
          },
          {
            type: "mrkdwn",
            text: "*作業時間:*\n#{(work.minutes / 60.0).round(1)}時間"
          },
          {
            type: "mrkdwn",
            text: "*残業時間:*\n#{overtime_hours}時間"
          }
        ]
      }
    ]
    
    if work.description.present?
      blocks << {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "*作業内容:*\n#{work.description.truncate(200)}"
        }
      }
    end
    
    blocks << {
      type: "section",
      text: {
        type: "mrkdwn",
        text: "⚠️ *マネージャーの承認が必要です*"
      }
    }
    
    blocks << {
      type: "context",
      elements: [
        {
          type: "mrkdwn",
          text: "#{Time.current.strftime('%Y-%m-%d %H:%M')} | TSUBASA 残業管理システム"
        }
      ]
    }
    
    SlackNotificationJob.perform_later(
      message,
      channel: '#残業申請',
      username: 'TSUBASA 残業管理',
      blocks: blocks,
      critical: true
    )
  rescue => e
    Rails.logger.error "残業申請通知のキューイング失敗: #{e.message}"
  end

  def send_overtime_cancel_notification(work, work_index)
    return unless Rails.env.production?
    
    message = "#{current_user.name}さんが残業申請を取り消しました"
    
    blocks = [
      {
        type: "header",
        text: {
          type: "plain_text",
          text: "↩️ 残業申請取消通知",
          emoji: true
        }
      },
      {
        type: "section",
        fields: [
          {
            type: "mrkdwn",
            text: "*取消者:*\n#{current_user.name}"
          },
          {
            type: "mrkdwn",
            text: "*日付:*\n#{@daily_report.date.strftime('%Y年%m月%d日')}"
          },
          {
            type: "mrkdwn",
            text: "*顧客/案件:*\n#{work.client.name} / #{work.project.name}"
          },
          {
            type: "mrkdwn",
            text: "*作業時間:*\n#{(work.minutes / 60.0).round(1)}時間"
          }
        ]
      },
      {
        type: "context",
        elements: [
          {
            type: "mrkdwn",
            text: "#{Time.current.strftime('%Y-%m-%d %H:%M')} | TSUBASA 残業管理システム"
          }
        ]
      }
    ]
    
    SlackNotificationJob.perform_later(
      message,
      channel: '#残業申請',
      username: 'TSUBASA 残業管理',
      blocks: blocks
    )
  rescue => e
    Rails.logger.error "残業取消通知のキューイング失敗: #{e.message}"
  end
end
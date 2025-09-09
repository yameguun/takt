# app/controllers/daily_reports_controller.rb
class DailyReportsController < BaseController
  include ActionView::Helpers::DateHelper
  before_action :set_daily_report, only: [:comments]

  def index
    @write_date = begin 
      Date.iso8601(params[:report_date]) 
    rescue 
      Time.zone.today 
    end

    @daily_report = current_user.daily_reports
                                .includes(daily_report_projects: [:task_type, { project: :client }])
                                .find_or_create_by(date: @write_date)
    
    @task_types = current_user.company.task_types.order(:name)

    yesterday = @write_date - 1.day
    @yesterday_report = current_user.daily_reports
                                   .includes(:daily_report_projects)
                                   .find_by(date: yesterday)
  end

  def create
    @write_date = begin 
      Date.iso8601(params[:report_date]) 
    rescue 
      Time.zone.today 
    end

    ActiveRecord::Base.transaction do
      @daily_report = current_user.daily_reports.find_or_create_by(date: @write_date)
      
      is_new_report = !@daily_report.persisted? || @daily_report.content.blank?
      
      existing_work_ids = @daily_report.daily_report_projects.pluck(:id)
      submitted_work_ids = []
      
      if params[:works].present?
        params[:works].each do |index, work_params|
          minutes = work_params[:minutes]
          
          if params[:existing_work_ids] && params[:existing_work_ids][index].present?
            work_id = params[:existing_work_ids][index].to_i
            daily_report_project = @daily_report.daily_report_projects.find_by(id: work_id)
            
            if daily_report_project
              daily_report_project.update!(
                client_id: work_params[:client_id],
                project_id: work_params[:project_id],
                task_type_id: work_params[:task_type_id],
                minutes: minutes,
                description: work_params[:description]
              )
              submitted_work_ids << daily_report_project.id
            end
          else
            daily_report_project = @daily_report.daily_report_projects.create!(
              client_id: work_params[:client_id],
              project_id: work_params[:project_id],
              task_type_id: work_params[:task_type_id],
              minutes: minutes,
              description: work_params[:description]
            )
            submitted_work_ids << daily_report_project.id
          end
        end
      end
      
      work_ids_to_delete = existing_work_ids - submitted_work_ids
      if work_ids_to_delete.any?
        @daily_report.daily_report_projects.where(id: work_ids_to_delete).destroy_all
      end
      
      @daily_report.update!(content: params[:report_content])
      
      send_daily_report_notification(@daily_report, is_new_report)
      
      flash[:success] = "日報を登録しました"
      redirect_to daily_reports_path(report_date: @write_date)
    end
    
  rescue ActiveRecord::RecordInvalid => e
   flash[:danger] = e.record.errors.full_messages.join(", ")
   redirect_to daily_reports_path(report_date: @write_date)
  rescue => e
   flash[:danger] = "予期せぬエラーが発生しました: #{e.message}"
   redirect_to daily_reports_path(report_date: @write_date)
  end

  def comments
    @comments = @daily_report.comments
                             .joins(:user)
                             .where('users.permission > 0')
                             .includes(:user)
                             .order(:created_at)
    
    respond_to do |format|
      format.json do
        render json: {
          status: 'success',
          comments: @comments.map { |comment| serialize_comment(comment) },
          report_date: @daily_report.date.strftime('%Y年%m月%d日'),
          report_content: @daily_report.content
        }
      end
    end
  end

  def previous_day_report
    target_date = begin
      Date.iso8601(params[:report_date])
    rescue
      Time.zone.today
    end
    yesterday = target_date - 1.day

    previous_report = current_user.daily_reports
                                  .includes(daily_report_projects: [:task_type, { project: :client }])
                                  .find_by(date: yesterday)

    if previous_report&.daily_report_projects&.any?
      render json: {
        status: 'success',
        report_content: previous_report.content,
        works: previous_report.daily_report_projects.map do |work|
          {
            client_id: work.client_id,
            client_name: work.client&.name,
            project_id: work.project_id,
            project_name: work.project&.name,
            task_type_id: work.task_type_id,
            task_type_name: work.task_type&.name,
            minutes: 0,
            description: work.description
          }
        end
      }
    else
      render json: { 
        status: 'not_found', 
        message: '昨日の作業記録が見つかりませんでした' 
      }, status: :not_found
    end
  rescue => e
    render json: { 
      status: 'error', 
      message: "データの取得中にエラーが発生しました: #{e.message}" 
    }, status: :internal_server_error
  end

  private

  def set_daily_report
    @daily_report = current_user.daily_reports.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { status: 'error', message: '日報が見つかりません' }, status: 404 }
    end
  end

  def serialize_comment(comment)
    {
      id: comment.id,
      content: comment.content,
      user_name: comment.user.name,
      user_avatar_url: comment.user.avatar.attached? ? url_for(comment.user.avatar) : nil,
      created_at: time_ago_in_words(comment.created_at) + '前',
      is_manager: comment.user.is_manager?
    }
  end

  def send_daily_report_notification(daily_report, is_new_report)
    return unless Rails.env.production?
    
    SlackNotificationJob.perform_later(
      build_daily_report_message(daily_report, is_new_report),
      channel: '#日報',
      username: 'TSUBASA 日報システム',
      blocks: build_daily_report_blocks(daily_report, is_new_report)
    )
  rescue => e
    Rails.logger.error "Slack通知のキューイング失敗: #{e.message}"
  end

  def build_daily_report_message(daily_report, is_new_report)
    action = is_new_report ? "作成" : "更新"
    "#{current_user.name}さんが#{daily_report.date.strftime('%Y年%m月%d日')}の日報を#{action}しました"
  end

  def build_daily_report_blocks(daily_report, is_new_report)
    total_minutes = daily_report.daily_report_projects.sum(:minutes)
    total_hours = (total_minutes / 60.0).round(1)
    overtime_minutes = [total_minutes - 480, 0].max
    overtime_hours = (overtime_minutes / 60.0).round(1)
    
    blocks = [
      {
        type: "header",
        text: {
          type: "plain_text",
          text: "📝 日報#{is_new_report ? '作成' : '更新'}通知",
          emoji: true
        }
      },
      {
        type: "section",
        fields: [
          {
            type: "mrkdwn",
            text: "*作成者:*\n#{current_user.name}"
          },
          {
            type: "mrkdwn",
            text: "*日付:*\n#{daily_report.date.strftime('%Y年%m月%d日')}"
          },
          {
            type: "mrkdwn",
            text: "*合計作業時間:*\n#{total_hours}時間"
          },
          {
            type: "mrkdwn",
            text: "*残業時間:*\n#{overtime_hours > 0 ? "#{overtime_hours}時間" : 'なし'}"
          }
        ]
      }
    ]

    if daily_report.daily_report_projects.any?
      work_details = daily_report.daily_report_projects.map do |work|
        hours = (work.minutes / 60.0).round(1)
        "• #{work.client.name} / #{work.project.name} (#{hours}h)"
      end.join("\n")
      
      blocks << {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "*作業内訳:*\n#{work_details}"
        }
      }
    end

    if daily_report.content.present?
      content_preview = daily_report.content.truncate(1000)
      blocks << {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "*日報内容:*\n```#{content_preview}```"
        }
      }
    end

    blocks << {
      type: "context",
      elements: [
        {
          type: "mrkdwn",
          text: "#{Time.current.strftime('%Y-%m-%d %H:%M')} | TSUBASA 日報管理システム"
        }
      ]
    }

    blocks
  end

  def daily_report_params
    formatted_params = {
      content: params[:report_content],
      daily_report_projects_attributes: params[:works]&.values || []
    }

    ActionController::Parameters.new(formatted_params).permit(
      :content,
      daily_report_projects_attributes: [
        :id,
        :client_id,
        :project_id,
        :task_type_id,
        :hours,
        :description,
        :_destroy
      ]
    )
  end
end
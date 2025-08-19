class DailyReportsController < BaseController
  include ActionView::Helpers::DateHelper
  before_action :set_daily_report, only: [:comments]

  def index
    # 改善案
    @write_date = begin 
      Date.iso8601(params[:report_date]) 
    rescue 
      Time.zone.today 
    end

    # 日報と関連プロジェクトをN+1問題なく取得
    @daily_report = current_user.daily_reports
                                .includes(daily_report_projects: [:task_type, { project: :client }])
                                .find_or_create_by(date: @write_date)
    
    # 作業区分をロード
    @task_types = current_user.company.task_types.order(:name)
  end

  def create
    # 改善案
    @write_date = begin 
      Date.iso8601(params[:report_date]) 
    rescue 
      Time.zone.today 
    end

    ActiveRecord::Base.transaction do
      @daily_report = current_user.daily_reports.find_or_create_by(date: @write_date)
      
      # 既存の作業記録のIDを取得
      existing_work_ids = @daily_report.daily_report_projects.pluck(:id)
      submitted_work_ids = []
      
      # 作業データの処理
      if params[:works].present?
        params[:works].each do |index, work_params|
          # hoursをminutesに変換
          minutes = work_params[:minutes]
          
          # 既存のレコードがあるかチェック（hidden fieldで送られてくるwork_idを使用）
          if params[:existing_work_ids] && params[:existing_work_ids][index].present?
            work_id = params[:existing_work_ids][index].to_i
            daily_report_project = @daily_report.daily_report_projects.find_by(id: work_id)
            
            if daily_report_project
              # 既存レコードの更新
              daily_report_project.update!(
                client_id: work_params[:client_id],
                project_id: work_params[:project_id],
                task_type_id: work_params[:task_type_id],
                minutes: minutes, # hoursからminutesに変換した値を使用
                description: work_params[:description]
              )
              submitted_work_ids << daily_report_project.id
            end
          else
            # 新規レコードの作成
            daily_report_project = @daily_report.daily_report_projects.create!(
              client_id: work_params[:client_id],
              project_id: work_params[:project_id],
              task_type_id: work_params[:task_type_id],
              minutes: minutes, # hoursからminutesに変換した値を使用
              description: work_params[:description]
            )
            submitted_work_ids << daily_report_project.id
          end
        end
      end
      
      # 削除されたレコードを削除（提出されなかったIDのレコードを削除）
      work_ids_to_delete = existing_work_ids - submitted_work_ids
      if work_ids_to_delete.any?
        @daily_report.daily_report_projects.where(id: work_ids_to_delete).destroy_all
      end
      
      # 日報本文の更新
      @daily_report.update!(content: params[:report_content])
      
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
    # マネージャーのコメントのみを取得
    @comments = @daily_report.comments
                             .joins(:user)
                             .where('users.permission > 0') # permission > 0 のユーザー（マネージャー）のみ
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

  private

  def set_daily_report
    # current_userの日報のみを対象とする
    @daily_report = current_user.daily_reports.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    # 日報が見つからない場合はJSONエラーを返す
    respond_to do |format|
      format.json { render json: { status: 'error', message: '日報が見つかりません' }, status: 404 }
    end
  end

  # コメントデータをJSON形式で整形するヘルパーメソッド
  def serialize_comment(comment)
    {
      id: comment.id,
      content: comment.content,
      user_name: comment.user.name,
      user_avatar_url: comment.user.avatar.attached? ? url_for(comment.user.avatar) : nil,
      created_at: time_ago_in_words(comment.created_at) + '前',
      is_manager: comment.user.is_manager? # マネージャーかどうかを識別するためのフラグ
    }
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
class DailyReportsController < BaseController

  def index
    @write_date = params[:report_date] || Date.today.strftime("%Y-%m-%d")
    @daily_report = current_user.daily_reports.find_or_create_by(date: @write_date)
  end

  def create
    @write_date = params[:report_date] || Date.today.strftime("%Y-%m-%d")

    ActiveRecord::Base.transaction do
      @daily_report = current_user.daily_reports.find_or_create_by(date: @write_date)
      
      # 既存の作業記録のIDを取得
      existing_work_ids = @daily_report.daily_report_projects.pluck(:id)
      submitted_work_ids = []
      
      # 作業データの処理
      if params[:works].present?
        params[:works].each do |index, work_params|
          # 既存のレコードがあるかチェック（hidden fieldで送られてくるwork_idを使用）
          if params[:existing_work_ids] && params[:existing_work_ids][index].present?
            work_id = params[:existing_work_ids][index].to_i
            daily_report_project = @daily_report.daily_report_projects.find_by(id: work_id)
            
            if daily_report_project
              # 既存レコードの更新
              daily_report_project.update!(
                client_id: work_params[:client_id],
                project_id: work_params[:project_id],
                minutes: work_params[:minutes],
                description: work_params[:description]
              )
              submitted_work_ids << daily_report_project.id
            end
          else
            # 新規レコードの作成
            daily_report_project = @daily_report.daily_report_projects.create!(
              client_id: work_params[:client_id],
              project_id: work_params[:project_id],
              minutes: work_params[:minutes],
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

  private

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
        :hours,
        :description,
        :_destroy
      ]
    )
  end
end
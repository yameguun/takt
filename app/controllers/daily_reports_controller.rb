class DailyReportsController < BaseController

  def create
    @write_date = params[:report_date] || Date.today.strftime("%Y-%m-%d")

    ActiveRecord::Base.transaction do
      @daily_report = current_user.daily_reports.find_or_initialize_by(date: @write_date)

      # 既存の作業項目を一度すべて削除する
      @daily_report.daily_report_projects.destroy_all

      # Strong Parameters を使って日報と新しい作業項目をまとめて更新
      # updateメソッドが assign_attributes と save を一度に行います
      if @daily_report.update(daily_report_params)
        # 成功
      else
        # バリデーションエラーなどで失敗した場合は例外が発生し、下の rescue に飛ぶ
        raise ActiveRecord::Rollback
      end
    end

    render json: @daily_report.as_json(include: :daily_report_projects), status: :ok

  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  rescue => e
    render json: { errors: [e.message] }, status: :internal_server_error
  end

  private

  # Strong Parameters を定義する private メソッド
  def daily_report_params
    # フロントエンドから送られてくるパラメータを、Railsが扱える形式に変換する
    formatted_params = {
      content: params[:report_content],
      # "works" というキーを "daily_report_projects_attributes" に変更
      daily_report_projects_attributes: params[:works]&.values || []
    }

    # ActionController::Parameters オブジェクトとして、許可する属性を定義
    ActionController::Parameters.new(formatted_params).permit(
      :content,
      daily_report_projects_attributes: [
        :client_id,
        :project_id,
        :hours,
        :description
      ]
    )
  end
end
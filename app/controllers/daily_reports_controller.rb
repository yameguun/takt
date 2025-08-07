class DailyReportsController < BaseController

  def create
    @write_date = params[:report_date] || Date.today.strftime("%Y-%m-%d")

    ActiveRecord::Base.transaction do
      @daily_report = current_user.daily_reports.find_or_initialize_by(date: @write_date)
      @daily_report.daily_report_projects.destroy_all

      if @daily_report.update(daily_report_params)
        # 成功メッセージをflashに格納します
        flash.now[:success] = "日報を提出しました。"
        # この後、Railsが自動的に create.turbo_stream.erb を探しに行きます
      else
        # バリデーションエラーなどで失敗した場合
        flash.now[:danger] = "入力内容に誤りがあります。内容を確認してください。"
        # フォームをエラーメッセージ付きで再描画するために、turbo_streamを描画します
        render :create, status: :unprocessable_entity and return
      end
    end

    redirect_to root_path(report_date: @write_date), flash: {success: "登録しました"}
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:danger] = e.record.errors.full_messages.join(", ")
    render :create, status: :unprocessable_entity
  rescue => e
    flash.now[:danger] = "予期せぬエラーが発生しました: #{e.message}"
    render :create, status: :internal_server_error
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
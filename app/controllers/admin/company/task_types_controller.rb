class Admin::Company::TaskTypesController < Admin::ApplicationController
  before_action :set_company
  before_action :set_task_type, only: %i[edit update destroy]

  def index
    @task_types = @company.task_types.order(created_at: :desc).page(params[:page])
  end

  def new
    @task_type = @company.task_types.new
  end

  def create
    @task_type = @company.task_types.new(task_type_params)
    if @task_type.save
      redirect_to admin_company_task_types_path(@company), flash: {success: "登録しました"}
    else
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @task_type.update(task_type_params)
      redirect_to admin_company_task_types_path(@company), flash: {success: "更新しました"}
    else
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task_type.destroy!
    redirect_to admin_company_task_types_path(@company), flash: {error: "削除しました"}, status: :see_other
  end

  # CSVインポート機能
  def import
    if params[:csv_file].blank?
      redirect_to admin_company_task_types_path(@company), flash: {alert: "CSVファイルを選択してください"}
      return
    end

    unless params[:csv_file].content_type.in?(%w[text/csv application/vnd.ms-excel])
      redirect_to admin_company_task_types_path(@company), flash: {alert: "CSVファイルのみアップロード可能です"}
      return
    end

    result = TaskType.import_csv(params[:csv_file], @company)
    
    if result[:errors].empty?
      redirect_to admin_company_task_types_path(@company), 
                  flash: {success: "#{result[:success_count]}件の作業区分をインポートしました"}
    else
      redirect_to admin_company_task_types_path(@company), 
                  flash: {alert: "インポートに失敗しました: #{result[:errors].join(', ')}"}
    end
  rescue => e
    redirect_to admin_company_task_types_path(@company), 
                flash: {alert: "CSVの処理中にエラーが発生しました: #{e.message}"}
  end

  # CSVテンプレートのダウンロード
  def download_template
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['作業区分名']
      csv << ['例：開発']
      csv << ['例：設計']
      csv << ['例：テスト']
    end

    send_data csv_data, 
              filename: "task_types_template_#{Date.current}.csv",
              type: 'text/csv; charset=shift_jis'
  end

  private

  def set_company
    @company = Company.find(params[:company_id])
  end

  def set_task_type
    @task_type = @company.task_types.find(params[:id])
  end

  def task_type_params
    params.require(:task_type).permit(:name)
  end
end
class Admin::Company::ProjectTypesController < Admin::ApplicationController
  before_action :set_company
  before_action :set_project_type, only: %i[edit update destroy]

  def index
    @project_types = @company.project_types.order(created_at: :desc).page(params[:page])
  end

  def new
    @project_type = @company.project_types.new
  end

  def create
    @project_type = @company.project_types.new(project_type_params)
    if @project_type.save
      redirect_to admin_company_project_types_path(@company), flash: {success: "登録しました"}
    else
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project_type.update(project_type_params)
      redirect_to admin_company_project_types_path(@company), flash: {success: "更新しました"}
    else
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project_type.destroy!
    redirect_to admin_company_project_types_path(@company), flash: {error: "削除しました"}, status: :see_other
  end

  # CSVインポート機能
  def import
    if params[:csv_file].blank?
      redirect_to admin_company_project_types_path(@company), flash: {alert: "CSVファイルを選択してください"}
      return
    end

    unless params[:csv_file].content_type.in?(%w[text/csv application/vnd.ms-excel])
      redirect_to admin_company_project_types_path(@company), flash: {alert: "CSVファイルのみアップロード可能です"}
      return
    end

    result = ProjectType.import_csv(params[:csv_file], @company)
    
    if result[:errors].empty?
      redirect_to admin_company_project_types_path(@company), 
                  flash: {success: "#{result[:success_count]}件の作業区分をインポートしました"}
    else
      redirect_to admin_company_project_types_path(@company), 
                  flash: {alert: "インポートに失敗しました: #{result[:errors].join(', ')}"}
    end
  rescue => e
    redirect_to admin_company_project_types_path(@company), 
                flash: {alert: "CSVの処理中にエラーが発生しました: #{e.message}"}
  end

  # CSVテンプレートのダウンロード
  def download_template
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['案件区分名']
      csv << ['例：WEB制作']
      csv << ['例：グラフィック制作']
      csv << ['例：ふるさと納税']
    end

    send_data csv_data, 
              filename: "案件区分_#{Date.current}.csv",
              type: 'text/csv; charset=shift_jis'
  end

  private

  def set_company
    @company = Company.find(params[:company_id])
  end

  def set_project_type
    @project_type = @company.project_types.find(params[:id])
  end

  def project_type_params
    params.require(:project_type).permit(:name)
  end
end

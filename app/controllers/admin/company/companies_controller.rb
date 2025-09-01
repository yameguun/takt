class Admin::Company::CompaniesController < Admin::ApplicationController
  before_action :set_company, only: %i[edit update destroy]

  # 会社一覧
  def index
    @companies = Company.all.order(created_at: :desc).page(params[:page])
  end

  # 新規作成フォーム
  def new
    @company = Company.new
  end

  # 新規作成処理
  def create
    @company = Company.new(company_params)
    if @company.save
      redirect_to admin_companies_path, flash: {success: "登録しました"}
    else
      # バリデーションエラーなどで保存に失敗した場合
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :new, status: :unprocessable_entity
    end
  end

  # 編集フォーム
  def edit
  end

  # 更新処理
  def update
    if @company.update(company_params)
      redirect_to admin_companies_path, flash: {success: "登録しました"}
    else
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :edit, status: :unprocessable_entity
    end
  end

  # 削除処理
  def destroy
    @company.destroy!
    redirect_to admin_companies_path, flash: {error: "削除しました"}, status: :see_other
  end

  private

  def company_params
    params.require(:company).permit(:name, :address, :phone_number, :email, :daily_report_description)
  end

  def set_company
    @company = Company.find(params[:id])
  end
end
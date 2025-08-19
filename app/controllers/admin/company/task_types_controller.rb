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

  private

  # 親リソースであるCompanyを取得
  def set_company
    @company = Company.find(params[:company_id])
  end

  # 編集・更新・削除対象のTaskTypeを取得
  def set_task_type
    @task_type = @company.task_types.find(params[:id])
  end

  # Strong Parameters
  def task_type_params
    params.require(:task_type).permit(:name)
  end
end

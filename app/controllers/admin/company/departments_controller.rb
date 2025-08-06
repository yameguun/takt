class Admin::Company::DepartmentsController < Admin::ApplicationController
  before_action :set_company
  before_action :set_department, only: %i[edit update destroy]

  # 部署一覧
  def index
    @departments = @company.departments.order(created_at: :desc).page(params[:page])
  end

  def new
    @department = @company.departments.new
  end

  def create
    @department = @company.departments.new(department_params)
    if @department.save
      redirect_to admin_company_departments_path(@company), flash: {success: "登録しました"}
    else
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @department.update(set_department)
      redirect_to admin_company_departments_path(@company), flash: {success: "登録しました"}
    else
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @department.destroy!
    redirect_to admin_company_departments_path(@company), flash: {error: "削除しました"}, status: :see_other
  end

  private

  def department_params
    params.require(:department).permit(:name)
  end

  def set_company
    @company = Company.find(params[:company_id])
  end

  def set_department
    @department = Department.find(params[:id])
  end
end

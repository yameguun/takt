class Admin::Company::ProjectsController < Admin::ApplicationController
  before_action :set_company
  before_action :set_client
  before_action :set_project, only: %i[edit update destroy]

  def index
    @projects = @client.projects.order(created_at: :desc).page(params[:page])
  end

  def new
    @project = @client.projects.new
  end

  def create
    @project = @client.projects.new(project_params)
    if @project.save
      redirect_to admin_company_client_projects_path(@company, @client), flash: {success: "登録しました"}
    else
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to admin_company_client_projects_path(@company, @client), flash: {success: "更新しました"}
    else
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy!
    redirect_to admin_company_client_projects_path(@company, @client), flash: {error: "削除しました"}, status: :see_other
  end

  private

  def set_company
    @company = Company.find(params[:company_id])
  end

  def set_client
    @client = @company.clients.find(params[:client_id])
  end

  def set_project
    @project = @client.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :sales, :project_type_id)
  end
end
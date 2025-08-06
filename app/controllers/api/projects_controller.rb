class Api::ProjectsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @projects = Project.where(client_id: params[:client_id])
    @projects = @projects.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?
  end
end

class Api::TaskTypesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @task_types = Company.find(params[:company_id]).task_types
    
    # 名前での検索
    if params[:name].present?
      @task_types = @task_types.where("name LIKE ?", "%#{params[:name]}%")
    end
    
    @task_types = @task_types.order(:name).limit(20)
    
    render json: {
      task_types: @task_types.map { |tt| { id: tt.id, name: tt.name } }
    }
  end
end
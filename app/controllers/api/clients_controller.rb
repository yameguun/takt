class Api::ClientsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @clients = Client.where(company_id: params[:company_id])
  end
end

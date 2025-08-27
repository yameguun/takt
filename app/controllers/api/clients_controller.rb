class Api::ClientsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @clients = Client.where(company_id: params[:company_id])

    if params[:name].present?
      @clients = @clients.where("name LIKE ? OR kana LIKE ?", "%#{params[:name]}%", "%#{params[:name]}%")
                         .order('name ASC')
    else
      # 空検索時は最近更新されたものを優先表示
      @clients = @clients.order(updated_at: :desc)
    end

    # limit パラメータ対応
    if params[:limit].present?
      @clients = @clients.limit(params[:limit].to_i)
    else
      # デフォルトで制限をかける（大量データ対策）
      @clients = @clients.limit(10) unless params[:name].present?
    end
  end
end
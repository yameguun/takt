class Admin::Company::ClientsController < Admin::ApplicationController
  before_action :set_company
  before_action :set_client, only: %i[edit update destroy]

  # 取引先一覧
  def index
    @clients = @company.clients.order(created_at: :desc).page(params[:page])
  end

  # 新規作成フォーム
  def new
    @client = @company.clients.new
  end

  # 新規作成処理
  def create
    @client = @company.clients.new(client_params)
    if @client.save
      redirect_to admin_company_clients_path(@company), flash: {success: "登録しました"}
    else
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :new, status: :unprocessable_entity
    end
  end

  # 編集フォーム
  def edit
  end

  # 更新処理
  def update
    if @client.update(client_params)
      redirect_to admin_company_clients_path(@company), flash: {success: "更新しました"}
    else
      flash.now[:alert] = '入力内容に誤りがあります。'
      render :edit, status: :unprocessable_entity
    end
  end

  # 削除処理
  def destroy
    @client.destroy!
    redirect_to admin_company_clients_path(@company), notice: '取引先を削除しました。', status: :see_other
  end

  private

  # 親リソースであるCompanyを取得
  def set_company
    @company = Company.find(params[:company_id])
  end

  # 編集・更新・削除対象のClientを取得
  def set_client
    @client = @company.clients.find(params[:id])
  end

  # Strong Parameters
  # permit()の中身は、実際のClientモデルのカラムに合わせてください
  def client_params
    params.require(:client).permit(:name, :kana, :address, :phone)
  end
end

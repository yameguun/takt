# app/controllers/admin/company/users_controller.rb
class Admin::Company::UsersController < Admin::ApplicationController
  before_action :set_company
  before_action :set_user, only: %i[edit update remove_avatar destroy]

  def index
    @users = @company.users.kept.order(created_at: :desc).page(params[:page])
  end

  def new
    @user = @company.users.new
  end

  def create
    @user = @company.users.new(user_params)
    
    if @user.save
      # 成功時のリダイレクトとメッセージ表示
      redirect_to admin_company_users_path(@company), 
                  flash: { success: "ユーザー「#{@user.name}」を登録しました。初回ログイン時にパスワード変更を促してください。" }
    else
      # エラー時の処理
      flash.now[:alert] = 'ユーザー登録に失敗しました。入力内容を確認してください。'
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # パスワード更新の特別処理
    update_params = user_params
    
    # パスワードフィールドが空の場合は更新対象から除外
    if params[:user][:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @user.update(update_params)
      redirect_to admin_company_users_path(@company), 
                  flash: { success: "ユーザー「#{@user.name}」の情報を更新しました。" }
    else
      flash.now[:alert] = 'ユーザー情報の更新に失敗しました。入力内容に誤りがあります。'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.discard!
      redirect_to admin_company_users_path(@company), 
                  flash: { error: "ユーザー「#{@user.name}」を削除しました。" }, 
                  status: :see_other
    else
      flash[:alert] = 'ユーザーの削除に失敗しました。'
      redirect_to admin_company_users_path(@company)
    end
  end

  # 画像削除アクション
  def remove_avatar
    @user.avatar.purge
    redirect_to edit_admin_company_user_path(@company, @user), 
                flash: {success: "画像を削除しました"}
  end

  private

  def user_params
    # 新規登録と編集で必要なパラメータを適切に許可
    permitted_params = [:company_id, :department_id, :name, :email, :unit_price, :permission, :avatar]
    
    # パスワード関連パラメータの条件付き許可
    if params[:user][:password].present?
      permitted_params += [:password, :password_confirmation]
    end
    
    params.require(:user).permit(permitted_params)
  end

  def set_company
    @company = Company.find(params[:company_id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "指定された会社が見つかりません。"
    redirect_to admin_companies_path
  end

  def set_user
    @user = @company.users.kept.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "指定されたユーザーが見つかりません。"
    redirect_to admin_company_users_path(@company)
  end
end
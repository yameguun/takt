class SessionsController < ApplicationController

  def new
  end

  def create
    @user = User.find_by(email: params[:email])

    if @user&.authenticate(params[:password])
      reset_session
      session[:user_id] = @user.id
      flash.now[:success] = "ログインしました"
      redirect_to root_path
    else
      flash.now[:error] = "メールアドレスまたはパスワードが違います"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    log_out
    flash.now[:success] = "ログアウトしました"
    redirect_to login_path
  end

  def switch_company
    unless can_switch_company?
      redirect_back(fallback_location: root_path, alert: '会社を切り替える権限がありません。')
      return
    end

    company_id = params[:company_id].to_i
    company = accessible_companies.find_by(id: company_id)

    if company
      session[:current_company_id] = company.id
      redirect_back(
        fallback_location: root_path, 
        notice: "#{company.name}に切り替えました。"
      )
    else
      redirect_back(
        fallback_location: root_path, 
        alert: '指定された会社にアクセスできません。'
      )
    end
  end
end

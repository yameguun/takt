require 'net/http'
require 'json'

class SlackAuthenticationsController < ApplicationController

  # ユーザーをSlackの認証ページにリダイレクトさせる
  def new
    client_id = ENV["SLACK_CLIENT_ID"]
    redirect_uri = ENV["SLACK_REDIRECT_URI"]
    scope = 'users.profile:read,users:read.email,users:read'

    session[:state] = SecureRandom.hex(16)

    slack_auth_url = "https://slack.com/oauth/v2/authorize?client_id=#{client_id}&scope=&user_scope=#{scope}&redirect_uri=#{redirect_uri}&state=#{session[:state]}"
    
    redirect_to slack_auth_url, allow_other_host: true
  end

  # Slackからのコールバックを処理
  def create
    # stateの検証（CSRF対策）
    if params[:state].blank? || params[:state] != session[:state]
      return redirect_to root_path, alert: '不正なリクエストです。'
    end
    session.delete(:state) # 検証後は不要なので削除

    if params[:error]
      return redirect_to root_path, alert: "認証に失敗しました: #{params[:error_description] || params[:error]}"
    end
    
    # 1. アクセストークンを取得
    access_token = request_access_token(params[:code])
    return redirect_to root_path, alert: 'アクセストークンの取得に失敗しました。' unless access_token

    # 2. ユーザー情報を取得
    slack_user_info = request_slack_user_info(access_token)
    return redirect_to root_path, alert: 'ユーザー情報の取得に失敗しました。' unless slack_user_info

    # 3. ユーザーを見つけてログイン処理
    # 既存のUserモデルと連携
    user = find_or_create_user(slack_user_info)
    
    # セッションにユーザーIDを保存してログイン状態にする
    # このlog_inメソッドはApplicationControllerで定義することを推奨（後述）
    log_in(user)

    redirect_to root_path, flash: {success: "ログインしました"}
  end

  private

  # codeを使ってアクセストークンをリクエスト
  def request_access_token(code)
    # (前回の回答と同じコードのため省略)
    uri = URI('https://slack.com/api/oauth.v2.access')
    response = Net::HTTP.post_form(uri, {
      code: code,
      client_id: ENV["SLACK_CLIENT_ID"],
      client_secret: ENV["SLACK_CLIENT_SECRET"],
      redirect_uri: ENV["SLACK_REDIRECT_URI"]
    })
    
    response_body = JSON.parse(response.body)
    response_body['ok'] ? response_body['authed_user']['access_token'] : nil
  end

  # アクセストークンを使ってユーザー情報をリクエスト
  def request_slack_user_info(access_token)
    # (前回の回答と同じコードのため省略)
    uri = URI('https://slack.com/api/users.profile.get')
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{access_token}"
    
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    
    response_body = JSON.parse(res.body)
    response_body['ok'] ? response_body['profile'] : nil
  end

  # Slackの情報をもとにUserを検索または作成
  def find_or_create_user(slack_info)
    # Slackのメールアドレスを元にユーザーを探す
    user = User.find_by(email: slack_info['email'])

    # ユーザーが見つからなければ作成する
    unless user
      user = User.create!(
        company: Company.all.first,
        email: slack_info['email'],
        name: slack_info['display_name_normalized'] || slack_info['real_name_normalized'],
        # パスワードは不要なため、SecureRandomでダミーを設定（バリデーションがある場合）
        # Userモデルの設計によります
        password: SecureRandom.hex(16)
        # avatar_url: slack_info['image_72'] # Avatarを保存するカラムがある場合
      )
    end
    user
  end
end
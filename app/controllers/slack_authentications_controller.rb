require 'net/http'
require 'json'
require 'uri'
require 'cgi'
require 'securerandom'

class SlackAuthenticationsController < ApplicationController
  # ユーザーをSlackの認証ページにリダイレクトさせる
  def new
    client_id    = ENV.fetch('SLACK_CLIENT_ID')
    redirect_uri = ENV.fetch('SLACK_REDIRECT_URI')

    # ユーザーのメールを取得するための user_scope
    user_scope = %w[users.profile:read users:read.email users:read].join(',')

    session[:state] = SecureRandom.hex(16)

    query = URI.encode_www_form(
      client_id: client_id,
      user_scope: user_scope,
      redirect_uri: redirect_uri,
      state: session[:state]
    )

    slack_auth_uri = URI::HTTPS.build(
      host: 'slack.com',
      path: '/oauth/v2/authorize',
      query: query
    )

    redirect_to slack_auth_uri.to_s, allow_other_host: true
  rescue KeyError => e
    redirect_to root_path, alert: "環境変数が未設定です: #{e.message}"
  end

  # Slackからのコールバックを処理
  def create
    # stateの検証（CSRF対策）
    if params[:state].blank? || params[:state] != session[:state]
      return redirect_to root_path, alert: '不正なリクエストです。'
    end
    session.delete(:state) # 検証後は不要なので削除

    if params[:error].present?
      return redirect_to root_path, flash: { error: "認証に失敗しました: #{params[:error_description] || params[:error]}" }
    end

    # 1. アクセストークンを取得（user token）
    user_access_token, _token_body = request_access_token(params[:code])
    unless user_access_token
      return redirect_to root_path, flash: { error: 'アクセストークンの取得に失敗しました。' }
    end

    # 2. ユーザー情報を取得（email含む）
    slack_profile, _raw_profile = request_slack_user_info(user_access_token)
    unless slack_profile
      return redirect_to root_path, flash: { error: 'ユーザー情報の取得に失敗しました。' }
    end

    email = slack_profile['email']&.downcase
    if email.blank?
      return redirect_to root_path, flash: { error: 'メールアドレスが取得できませんでした（users:read.email の許可が必要です）。' }
    end

    # 3. メールアドレスのホワイトリスト検証（メール or ドメイン）
    unless allowed_email?(email)
      return redirect_to root_path, flash: { error: 'このメールアドレスではログインできません（ホワイトリスト外）。' }
    end

    # 4. ユーザーを見つけてログイン処理
    user = find_or_create_user(slack_profile)
    log_in(user) # ApplicationController などで定義されている想定

    redirect_to root_path, flash: { success: 'ログインしました' }
  end

  private

  # codeを使ってアクセストークンをリクエスト（Slack OAuth v2）
  # 戻り値: [user_access_token(String or nil), response_body(Hash)]
  def request_access_token(code)
    uri = URI('https://slack.com/api/oauth.v2.access')
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/x-www-form-urlencoded'
    req.set_form_data(
      code: code,
      client_id: ENV['SLACK_CLIENT_ID'],
      client_secret: ENV['SLACK_CLIENT_SECRET'],
      redirect_uri: ENV['SLACK_REDIRECT_URI']
    )

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    body = JSON.parse(res.body) rescue {}

    return [nil, body] unless res.is_a?(Net::HTTPSuccess) && body['ok']
    [body.dig('authed_user', 'access_token'), body]
  rescue => e
    Rails.logger.error("[SlackOAuth] token exchange error: #{e.class}: #{e.message}")
    [nil, {}]
  end

  # アクセストークンを使ってユーザー情報（プロフィール）をリクエスト
  # users.profile.get は user token + users.profile:read が必要
  # email フィールドは users:read.email が付与されている場合に含まれます
  # 戻り値: [profile(Hash) or nil, response_body(Hash)]
  def request_slack_user_info(access_token)
    uri = URI('https://slack.com/api/users.profile.get')
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{access_token}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    body = JSON.parse(res.body) rescue {}

    return [nil, body] unless res.is_a?(Net::HTTPSuccess) && body['ok']
    [body['profile'] || {}, body]
  rescue => e
    Rails.logger.error("[SlackOAuth] user info error: #{e.class}: #{e.message}")
    [nil, {}]
  end

  # メールアドレスのホワイトリスト判定
  # 環境変数:
  #   SLACK_ALLOWED_EMAILS      例) alice@your-company.co.jp,bob@group.co.jp
  #   SLACK_ALLOWED_EMAIL_DOMAINS 例) your-company.co.jp,group.co.jp
  def allowed_email?(email)
    return false if email.blank?

    allowed_emails  = ENV.fetch('SLACK_ALLOWED_EMAILS', '').split(',').map { |s| s.strip.downcase }.reject(&:empty?)
    allowed_domains = ENV.fetch('SLACK_ALLOWED_EMAIL_DOMAINS', '').split(',').map { |s| s.strip.downcase }.reject(&:empty?)

    return true if allowed_emails.include?(email)

    domain = email.split('@', 2).last
    allowed_domains.include?(domain)
  end

  # Slackの情報をもとにUserを検索または作成
  def find_or_create_user(slack_profile)
    email = slack_profile['email'].downcase
    user = User.find_by(email: email)
    return user if user

    User.create!(
      company: Company.all.first,
      department: Department.all.first,
      email: email,
      name: slack_profile['display_name_normalized'].presence ||
            slack_profile['real_name_normalized'].presence ||
            email.split('@').first,
      # パスワードが必須な場合はダミーを設定
      password: SecureRandom.hex(16)
      # avatar_url: slack_profile['image_72'] # Avatarを保存するカラムがある場合
    )
  end
end
class Manager::DailyReportsController < BaseController
  require 'net/http'
  require 'json'
  require 'uri'

  before_action :require_manager
  before_action :set_target_date, only: [:index]
  before_action :set_daily_report, only: [:generate_ai_comment]

  def index
    @users = current_user.company.users.kept
      .includes(:department)
      .where(permission: 0)
      .order(:name)

    @reports_by_user_id = DailyReport
      .where(user_id: @users.select(:id), date: @target_date)
      .includes({ comments: :user }, daily_report_projects: { project: :client })
      .where.not(daily_report_projects: { description: nil })
      .index_by(&:user_id)

    @report_statistics = calculate_statistics
  end

  def generate_ai_comment
    unless @daily_report.user.company_id == current_user.company_id
      render json: { status: 'error', message: '権限がありません' }, status: :forbidden
      return
    end

    report_content = build_report_query(@daily_report)
    if report_content.blank?
      render json: { status: 'error', message: '日報内容が見つかりません' }, status: :unprocessable_entity
      return
    end

    begin
      ai_comment = call_ai_api(report_content)
      render json: { status: 'success', comment: ai_comment }
    rescue => e
      Rails.logger.error "AI API Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { status: 'error', message: e.message }, status: :internal_server_error
    end
  end

  private

  def require_manager
    unless current_user&.is_manager?
      flash[:danger] = "この機能を利用する権限がありません"
      redirect_to root_path
    end
  end

  def set_target_date
    @target_date = begin
      Date.iso8601(params[:date]) if params[:date].present?
    rescue ArgumentError
      nil
    end || Time.zone.today

    @prev_date = @target_date - 1.day
    @next_date = @target_date + 1.day
  end

  def set_daily_report
    @daily_report = DailyReport.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: '指定された日報が見つかりません' }, status: :not_found
  end

  def calculate_statistics
    reports_with_content = @reports_by_user_id.values

    minutes_scope = DailyReportProject
      .joins(:daily_report)
      .where(daily_reports: { user_id: @users.select(:id), date: @target_date })

    {
      submitted_count: reports_with_content.size,
      total_users: @users.size,
      submission_rate: @users.size.zero? ? 0 : ((reports_with_content.size.to_f / @users.size) * 100).round(1),
      total_work_hours: (minutes_scope.sum(:minutes) / 60.0).round(1),
      overtime_requests: minutes_scope.where(is_overtime_requested: true, is_overtime_approved: false).count
    }
  end

  def build_report_query(report)
    content_parts = []

    content_parts << "日付: #{report.date.strftime('%Y年%m月%d日')}"
    content_parts << "社員名: #{report.user.name}"
    content_parts << "部署: #{report.user.department&.name || '未設定'}"

    if report.daily_report_projects.any?
      content_parts << "\n【作業記録】"
      report.daily_report_projects.each do |work|
        work_info = []
        work_info << "・顧客: #{work.project&.client&.name || '不明'}"
        work_info << "案件: #{work.project&.name || '不明'}"
        work_info << "作業時間: #{(work.minutes / 60.0).round(1)}時間"

        if work.is_overtime_requested
          status = work.is_overtime_approved ? "承認済み" : "申請中"
          work_info << "残業申請: #{status}"
        end

        if work.description.present?
          work_info << "内容: #{work.description}"
        end

        content_parts << work_info.join(", ")
      end

      total_hours = (report.daily_report_projects.sum(&:minutes) / 60.0).round(1)
      content_parts << "総作業時間: #{total_hours}時間"
    end

    if report.content.present?
      content_parts << "\n【日報内容】"
      content_parts << report.content
    end

    content_parts.join("\n")
  end

  def call_ai_api(query)
    api_key = ENV['AI_API_KEY']
    raise 'AI APIキーが設定されていません' if api_key.blank?

    uri = URI('https://suncac.xvps.jp/v1/completion-messages')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60
    http.open_timeout = 10

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{api_key}"
    request['Content-Type'] = 'application/json'
    # 重要: AcceptヘッダーをJSONに変更（SSEではなく）
    request['Accept'] = 'application/json'

    request_body = {
      inputs: { query: query },
      response_mode: "blocking",
      user: current_user.name
    }
    request.body = request_body.to_json

    begin
      response = http.request(request)
      
      # HTTPステータスコードのチェック
      unless response.is_a?(Net::HTTPSuccess)
        error_message = "API request failed with status: #{response.code}"
        begin
          error_body = JSON.parse(response.body)
          if error_body['message']
            error_message += " - #{error_body['message']}"
          end
        rescue JSON::ParserError
          error_message += " - #{response.body.truncate(200)}"
        end
        Rails.logger.error "AI API HTTP Error: #{error_message}"
        raise error_message
      end

      # レスポンスボディを直接JSONとしてパース（SSE処理は不要）
      response_data = JSON.parse(response.body)
      
      # APIの実際のレスポンス形式に基づいて処理
      if response_data['event'] == 'message' && response_data['answer']
        # Unicode エスケープシーケンスをデコード
        answer = decode_unicode_escapes(response_data['answer'])
        
        # 空の回答をチェック
        if answer.strip.empty?
          raise 'AIから空のレスポンスが返されました。再試行してください。'
        end
        
        return answer.strip
      elsif response_data['event'] == 'error'
        error_msg = response_data['message'] || 'AI APIからの不明なエラー'
        raise "AI APIエラー: #{error_msg}"
      else
        # 予期しないレスポンス形式
        Rails.logger.error "Unexpected API response format: #{response_data}"
        raise 'AIから予期しないレスポンス形式が返されました。'
      end

    rescue Net::TimeoutError => e
      Rails.logger.error "AI API Timeout: #{e.message}"
      raise 'AI APIの応答がタイムアウトしました。しばらく待ってから再試行してください。'
    rescue Net::HTTPError => e
      Rails.logger.error "AI API HTTP Error: #{e.message}"
      raise 'AI APIとの通信でエラーが発生しました。ネットワーク接続を確認してください。'
    rescue JSON::ParserError => e
      Rails.logger.error "AI API JSON Parse Error: #{e.message}"
      Rails.logger.error "Response body: #{response&.body}"
      raise 'AI APIからの応答を解析できませんでした。'
    rescue StandardError => e
      Rails.logger.error "AI API Standard Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise "AI APIでエラーが発生しました: #{e.message}"
    end
  end

  # Unicode エスケープシーケンスのデコード（APIレスポンスに必要）
  def decode_unicode_escapes(text)
    return '' if text.nil?

    text.gsub(/\\u([0-9a-fA-F]{4})/) do
      code_point = Regexp.last_match(1).hex
      [code_point].pack('U*')
    end
  rescue => e
    Rails.logger.warn "Unicode decode error: #{e.message}"
    text
  end
end
class WelcomeController < BaseController
  def index
    # データが存在する月を取得（非マネージャーのデータのみ対象）
    @available_months = get_available_months
    
    # 選択された月の決定
    current_ym = Time.zone.now.strftime("%Y-%m")
    @selected_month_ym = determine_selected_month(params[:month], current_ym)
    
    # 選択された月の期間設定
    if @selected_month_ym.present?
      @target_date = Time.zone.parse("#{@selected_month_ym}-01")
      @start_date = @target_date.beginning_of_month.strftime("%Y-%m-%d 00:00:00")
      @end_date = @target_date.end_of_month.strftime("%Y-%m-%d 23:59:59")
      @current_month = @target_date.strftime("%Y年%-m月")
    else
      # データが存在しない場合のフォールバック
      @target_date = Time.zone.now
      @start_date = @target_date.beginning_of_month.strftime("%Y-%m-%d 00:00:00")
      @end_date = @target_date.end_of_month.strftime("%Y-%m-%d 23:59:59")
      @current_month = @target_date.strftime("%Y年%-m月")
    end
    
    # 月の残業時間上限
    @overtime_limit = 45.0

    # 残業時間集計SQL（マネージャー除外）
    sql = ApplicationRecord.sanitize_sql_array([<<-"EOS", @start_date, @end_date])
(
SELECT 
  users.*,
  departments.name AS department_name,
  COALESCE(SUM(daily_report_projects.minutes), 0) AS total_minutes,
  COALESCE(SUM(daily_report_projects.minutes) / 60.0, 0) AS total_hours
FROM users
INNER JOIN departments ON users.department_id = departments.id
LEFT JOIN daily_reports ON users.id = daily_reports.user_id 
  AND daily_reports.date BETWEEN ? AND ?
LEFT JOIN daily_report_projects ON daily_reports.id = daily_report_projects.daily_report_id
  AND daily_report_projects.is_overtime_approved = 1
  AND daily_report_projects.is_overtime_requested = 1
WHERE users.permission = 0
GROUP BY users.id, departments.name
ORDER BY total_hours DESC
) AS users
EOS
    @users = User.kept.from(sql)
  end
  
  private
  
  def calculate_status(hours, limit)
    percentage = (hours / limit * 100).to_i
    
    if percentage >= 100
      { label: 'label-danger', text: '上限到達', progress_class: 'progress-bar-danger' }
    elsif percentage >= 80
      { label: 'label-warning', text: '要注意', progress_class: 'progress-bar-warning' }
    elsif percentage >= 40
      { label: 'label-info', text: '標準', progress_class: 'progress-bar-info' }
    else
      { label: 'label-success', text: '余裕あり', progress_class: 'progress-bar-success' }
    end
  end
  
  def get_available_months
    # 非マネージャーの残業データが存在する月を取得（MySQL向け最適化）
    sql = <<-SQL
      SELECT DISTINCT DATE_FORMAT(daily_reports.date, '%Y-%m') AS ym
      FROM daily_reports
      INNER JOIN users
        ON users.id = daily_reports.user_id
        AND users.permission = 0
      INNER JOIN daily_report_projects 
        ON daily_reports.id = daily_report_projects.daily_report_id
        AND daily_report_projects.is_overtime_approved = 1
        AND daily_report_projects.is_overtime_requested = 1
        AND daily_report_projects.minutes > 0
      ORDER BY ym DESC
    SQL

    available_months = ApplicationRecord.connection.select_values(sql)
    
    available_months.map do |ym|
      dt = Time.zone.parse("#{ym}-01")
      { value: ym, label: dt.strftime("%Y年%-m月") }
    end
  end
  
  def determine_selected_month(param_month, current_ym)
    available_month_values = @available_months.map { |m| m[:value] }
    
    if param_month.present?
      # パラメータで指定された月が有効かチェック
      begin
        Time.zone.parse("#{param_month}-01") # 形式チェック
        return param_month if available_month_values.include?(param_month)
      rescue ArgumentError
        flash.now[:warning] = "指定された月の形式が不正です。"
      end
    end
    
    # 現在月にデータがあるかチェック
    return current_ym if available_month_values.include?(current_ym)
    
    # 最新のデータがある月を返す
    available_month_values.first
  end
  
  helper_method :calculate_status
end
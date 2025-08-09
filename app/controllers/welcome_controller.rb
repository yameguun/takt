class WelcomeController < BaseController
  def index
    # 今月のタスクを集計
    
    # 月初
    @start_date = Time.zone.now.beginning_of_month.strftime("%Y-%m-%d 00:00:00")
    # 月末
    @end_date = Time.zone.now.end_of_month.strftime("%Y-%m-%d 23:59:59")
    
    # 現在の年月を取得
    @current_month = Time.zone.now.strftime("%Y年%-m月")
    
    # 月の残業時間上限（設定可能にする場合は定数やDBから取得）
    @overtime_limit = 45.0

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
GROUP BY users.id, departments.name
ORDER BY total_hours DESC
) AS users
EOS
    @users = User.from(sql)
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
  
  helper_method :calculate_status
end

class WelcomeController < BaseController
  def index
    # 今月のタスクを集計

    # 月初
    @start_date = Time.zone.now.beginning_of_month.strftime("%Y-%m-%d 00:00:00")
    # 月末
    @end_date = Time.zone.now.end_of_month.strftime("%Y-%m-%d 23:59:59")

    sql = ApplicationRecord.sanitize_sql_array([<<-"EOS", @start_date, @end_date])
(
SELECT 
  users.*,
  departments.name AS department_name,
  SUM(daily_report_projects.minutes) AS total_minutes,
  SUM(daily_report_projects.minutes) / 60.0 AS total_hours
FROM users
INNER JOIN departments ON users.department_id = departments.id
INNER JOIN daily_reports ON users.id = daily_reports.user_id
INNER JOIN daily_report_projects ON daily_reports.id = daily_report_projects.daily_report_id
WHERE daily_reports.date BETWEEN ? AND ?
AND daily_report_projects.is_overtime_approved = 1
AND daily_report_projects.is_overtime_requested = 1
GROUP BY users.id, departments.name
ORDER BY total_minutes DESC
) AS users
EOS
    @users = User.from(sql)
  end
end

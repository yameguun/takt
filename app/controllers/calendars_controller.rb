class CalendarsController < BaseController

  def show
    @current_date = parse_month(params[:year], params[:month])
    range_start = @current_date.beginning_of_month.beginning_of_week(:sunday)
    range_end = @current_date.end_of_month.end_of_week(:sunday)

    # 効率的なデータ取得（コメント情報も含む）
    reports = current_user.daily_reports
                          .includes(:daily_report_projects, comments: :user)
                          .where(date: range_start..range_end)

    @reports_by_date = reports.index_by(&:date)
    @daily_reports_dates = reports.pluck(:date).to_set

    # コメント数の集計（マネージャーのコメントのみ）
    @manager_comments_count_by_date = reports.joins(:comments)
                                            .joins('JOIN users ON comments.user_id = users.id')
                                            .where('users.permission > 0')
                                            .group(:date)
                                            .count

    # 残業データの計算（フラグベース + 時間ベース）
    overtime_data = calculate_overtime_data(reports, range_start, range_end)
    @overtime_dates = overtime_data[:dates]
    @overtime_hours_by_date = overtime_data[:hours_by_date]
    @overtime_minutes_by_date = overtime_data[:minutes_by_date]
  end

  private

  def parse_month(year_param, month_param)
    year = (year_param || Date.current.year).to_i
    month = (month_param || Date.current.month).to_i
    Date.new(year, month, 1)
  rescue ArgumentError
    Date.current.beginning_of_month
  end

  def calculate_overtime_data(reports, range_start, range_end)
    overtime_dates = Set.new
    overtime_hours_by_date = {}
    overtime_minutes_by_date = {}

    # 効率的なクエリでプロジェクトデータを取得
    project_data = DailyReportProject
                   .joins(:daily_report)
                   .where(daily_reports: { user_id: current_user.id, date: range_start..range_end })
                   .group('daily_reports.date')
                   .group('daily_reports.date', 'daily_report_projects.is_overtime_requested', 'daily_report_projects.is_overtime_approved')
                   .sum(:minutes)

    # 日別の合計時間を計算
    daily_totals = DailyReportProject
                   .joins(:daily_report)
                   .where(daily_reports: { user_id: current_user.id, date: range_start..range_end })
                   .group('daily_reports.date')
                   .sum(:minutes)

    # フラグベースの残業判定
    flag_overtime_dates = DailyReportProject
                          .joins(:daily_report)
                          .where(daily_reports: { user_id: current_user.id, date: range_start..range_end })
                          .where('is_overtime_requested = ? OR is_overtime_approved = ?', true, true)
                          .group('daily_reports.date')
                          .count
                          .keys
                          .to_set

    # 時間ベースの残業判定（8時間 = 480分を超過）
    daily_work_minutes = 480
    daily_totals.each do |date, total_minutes|
      if total_minutes > daily_work_minutes
        overtime_minutes = total_minutes - daily_work_minutes
        overtime_dates.add(date)
        overtime_hours_by_date[date] = (overtime_minutes / 60.0).round(1)
        overtime_minutes_by_date[date] = overtime_minutes
      end
    end

    # フラグベースの残業も追加
    flag_overtime_dates.each do |date|
      overtime_dates.add(date)
      unless overtime_hours_by_date[date]
        # フラグは立っているが時間超過していない場合
        overtime_hours_by_date[date] = 0
        overtime_minutes_by_date[date] = 0
      end
    end

    {
      dates: overtime_dates,
      hours_by_date: overtime_hours_by_date,
      minutes_by_date: overtime_minutes_by_date
    }
  end
end
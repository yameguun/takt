class DailyReportsController < BaseController

  def create
    @write_date = params[:date] || Date.today.strftime("%Y-%m-%d")

    # 記入途中の日報があるか確認する
    @daily_report = current_user.daily_reports.find_by(date: @write_date)

    if @daily_report.nil?
      @daily_report = current_user.daily_reports.new
      @daily_report.date = @write_date
      @daily_report.save!
    end
  end
end

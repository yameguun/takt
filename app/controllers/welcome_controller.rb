class WelcomeController < BaseController

  def index
    @write_date = params[:report_date] || Date.today.strftime("%Y-%m-%d")
    @daily_report = current_user.daily_reports.find_or_initialize_by(date: @write_date)
  end
end

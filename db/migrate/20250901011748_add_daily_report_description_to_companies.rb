class AddDailyReportDescriptionToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :daily_report_description, :text
  end
end

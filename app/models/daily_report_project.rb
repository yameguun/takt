# == Schema Information
#
# Table name: daily_report_projects
#
#  id              :bigint           not null, primary key
#  work_times      :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  client_id       :bigint           not null
#  daily_report_id :bigint           not null
#  project_id      :bigint           not null
#
# Indexes
#
#  index_daily_report_projects_on_daily_report_id  (daily_report_id)
#
class DailyReportProject < ApplicationRecord
  belongs_to :daily_report, optional: true
  belongs_to :project, optional: true

  validates :work_times, presence: true, numericality: true
end

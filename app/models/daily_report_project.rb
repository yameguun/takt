# == Schema Information
#
# Table name: daily_report_projects
#
#  id                    :bigint           not null, primary key
#  description           :text(65535)
#  hours                 :integer          default(0), not null
#  is_overtime_approved  :boolean          default(FALSE), not null
#  is_overtime_requested :boolean          default(FALSE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  client_id             :bigint           not null
#  daily_report_id       :bigint           not null
#  project_id            :bigint           not null
#
# Indexes
#
#  index_daily_report_projects_on_daily_report_id  (daily_report_id)
#
class DailyReportProject < ApplicationRecord
  belongs_to :daily_report, inverse_of: :daily_report_projects
  belongs_to :project, optional: true

  validates :hours, presence: true, numericality: true
end

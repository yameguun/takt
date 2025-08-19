# == Schema Information
#
# Table name: daily_report_projects
#
#  id                    :bigint           not null, primary key
#  description           :text(65535)
#  is_overtime_approved  :boolean          default(FALSE), not null
#  is_overtime_requested :boolean          default(FALSE), not null
#  minutes               :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  client_id             :bigint           not null
#  daily_report_id       :bigint           not null
#  project_id            :bigint           not null
#  task_type_id          :bigint           not null
#
# Indexes
#
#  index_daily_report_projects_on_daily_report_id  (daily_report_id)
#
class DailyReportProject < ApplicationRecord
  belongs_to :daily_report, inverse_of: :daily_report_projects
  belongs_to :project, optional: false
  belongs_to :client, optional: false
  belongs_to :task_type, optional: false

  validates :minutes, numericality: { 
    only_integer: true, 
    greater_than: 0, 
    less_than_or_equal_to: 1440 
  }
  validate :client_matches_project
  
  private
  
  def client_matches_project
    return if project_id.blank? || client_id.blank?
    errors.add(:client_id, 'が案件の顧客と一致しません') if project&.client_id != client_id
  end
end

# == Schema Information
#
# Table name: daily_reports
#
#  id         :bigint           not null, primary key
#  content    :text(65535)
#  date       :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_daily_reports_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class DailyReport < ApplicationRecord
  belongs_to :user
  has_many :daily_report_projects, inverse_of: :daily_report, dependent: :destroy

  accepts_nested_attributes_for :daily_report_projects

  validates :date, presence: true
end

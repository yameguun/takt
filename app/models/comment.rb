# == Schema Information
#
# Table name: comments
#
#  id              :bigint           not null, primary key
#  content         :text(65535)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  daily_report_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_comments_on_daily_report_id  (daily_report_id)
#  index_comments_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (daily_report_id => daily_reports.id)
#  fk_rails_...  (user_id => users.id)
#
class Comment < ApplicationRecord
  belongs_to :daily_report
  belongs_to :user

  validates :content, presence: true
end

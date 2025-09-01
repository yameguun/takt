# == Schema Information
#
# Table name: companies
#
#  id                       :bigint           not null, primary key
#  daily_report_description :text(65535)
#  name                     :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :departments, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :task_types, dependent: :destroy
  has_many :project_types, dependent: :destroy

  validates :name, presence: true
end

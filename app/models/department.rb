# == Schema Information
#
# Table name: departments
#
#  id         :integer          not null, primary key
#  company_id :integer          not null
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_departments_on_company_id  (company_id)
#  index_departments_on_name        (name) UNIQUE
#

class Department < ApplicationRecord
  belongs_to :company

  validates :name, presence: true, uniqueness: true
end

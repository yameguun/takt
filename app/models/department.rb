# == Schema Information
#
# Table name: departments
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_departments_on_company_id  (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#

class Department < ApplicationRecord
  belongs_to :company

  validates :name, presence: true, uniqueness: true
end

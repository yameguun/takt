# == Schema Information
#
# Table name: companies
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Company < ApplicationRecord

  has_many :users, dependent: :destroy
  has_many :departments, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end

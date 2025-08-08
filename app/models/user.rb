# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email           :string(255)      not null
#  name            :string(255)
#  password_digest :string(255)
#  permission      :integer          default(0), not null
#  unit_price      :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  department_id   :integer
#
# Indexes
#
#  index_users_on_company_id  (company_id)
#  index_users_on_email       (email) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#

class User < ApplicationRecord
  has_secure_password

  belongs_to :company
  belongs_to :department, optional: true

  has_one :authentication, dependent: :destroy
  
  has_many :daily_reports, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :unit_price, presence: true, numericality: true

  def is_manager?
    self.permission > 0
  end
end

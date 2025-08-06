# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  company_id      :integer          not null
#  email           :string(255)      not null
#  password_digest :string(255)
#  name            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_company_id  (company_id)
#  index_users_on_email       (email) UNIQUE
#

class User < ApplicationRecord
  has_secure_password

  has_one :authentication, dependent: :destroy
  belongs_to :company

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end

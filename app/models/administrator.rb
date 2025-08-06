# == Schema Information
#
# Table name: administrators
#
#  id              :integer          not null, primary key
#  email           :string(255)
#  password_digest :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_administrators_on_email  (email) UNIQUE
#

class Administrator < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true
end

# == Schema Information
#
# Table name: clients
#
#  id         :integer          not null, primary key
#  company_id :integer          not null
#  name       :string(255)
#  kana       :string(255)
#  address    :text(65535)
#  phone      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_clients_on_company_id  (company_id)
#

class Client < ApplicationRecord
  belongs_to :company

  validates :name, presence: true
end

# == Schema Information
#
# Table name: clients
#
#  id         :bigint           not null, primary key
#  address    :text(65535)
#  kana       :string(255)
#  name       :string(255)
#  phone      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_clients_on_company_id  (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#

class Client < ApplicationRecord
  belongs_to :company

  has_many :projects, dependent: :destroy

  validates :name, presence: true
end

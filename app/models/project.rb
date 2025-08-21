# == Schema Information
#
# Table name: projects
#
#  id              :bigint           not null, primary key
#  description     :text(65535)
#  name            :string(255)      not null
#  sales           :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  client_id       :bigint           not null
#  project_type_id :bigint
#
# Indexes
#
#  index_projects_on_client_id  (client_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id)
#
class Project < ApplicationRecord
  belongs_to :client
  belongs_to :project_type, optional: false

  validates :name, presence: true
  validates :sales, presence: true, numericality: true
end

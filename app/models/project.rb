class Project < ApplicationRecord
  belongs_to :client

  validates :name, presence: true
  validates :sales, presence: true, numericality: true
end

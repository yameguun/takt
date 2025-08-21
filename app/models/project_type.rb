# == Schema Information
#
# Table name: project_types
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_project_types_on_company_id  (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
class ProjectType < ApplicationRecord
  belongs_to :company
  validates :name, presence: true, uniqueness: { scope: :company_id }

  # CSVインポート処理
  def self.import_csv(file, company)
    errors = []
    success_count = 0
    
    CSV.foreach(file.path, headers: true, encoding: 'UTF-8:UTF-8') do |row|
      next if row['案件区分名'].blank?
      
      project_type = company.project_types.find_or_initialize_by(name: row['案件区分名'].strip)
      
      if project_type.new_record?
        if project_type.save
          success_count += 1
        else
          errors << "#{row['案件区分名']}: #{project_type.errors.full_messages.join(', ')}"
        end
      else
        errors << "#{row['案件区分名']}: 既に登録されています"
      end
    rescue => e
      errors << "行の処理中にエラー: #{e.message}"
    end
    
    { success_count: success_count, errors: errors }
  end
end

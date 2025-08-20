# lib/tasks/csv_import.rake
require 'csv'

namespace :csv do
  desc "Import data from CSV file"
  task import: :environment do
    csv_file_path = Rails.root.join('data', 'project_result.csv')

    suncac = Company.find_or_create_by!(name: 'サンカクキカク')

    CSV.foreach(csv_file_path, headers: true) do |row|
      client = Client.find_or_create_by(company: suncac, name: row["顧客"])
      client.projects.create(name: row["案件名"], sales: row["売上"].to_i, description: row["社内メモ"])
    end

    puts "CSV import completed!"
  end
end

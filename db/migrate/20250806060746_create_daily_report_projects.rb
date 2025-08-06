class CreateDailyReportProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_report_projects do |t|
      t.bigint :daily_report_id, null: false
      t.bigint :client_id, null: false
      t.bigint :project_id, null: false
      t.integer :work_times, null: false, default: 0

      t.timestamps
    end

    add_index :daily_report_projects, :daily_report_id
  end
end

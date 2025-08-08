class CreateDailyReportProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_report_projects do |t|
      t.bigint :daily_report_id, null: false
      t.bigint :client_id, null: false
      t.bigint :project_id, null: false
      t.integer :hours, null: false, default: 0
      t.text :description
      t.boolean :is_overtime_requested, null: false, default: false
      t.boolean :is_overtime_approved, null: false, default: false

      t.timestamps
    end

    add_index :daily_report_projects, :daily_report_id
  end
end

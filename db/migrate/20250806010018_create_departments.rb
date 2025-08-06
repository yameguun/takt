class CreateDepartments < ActiveRecord::Migration[8.0]
  def change
    create_table :departments do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end

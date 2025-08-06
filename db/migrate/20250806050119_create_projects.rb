class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :client, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :sales, null: false, default: 0

      t.timestamps
    end
  end
end

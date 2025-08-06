class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.string :kana
      t.text :address
      t.string :phone

      t.timestamps
    end
  end
end

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.references :company, null: false, foreign_key: true
      t.integer :department_id
      t.string :email, null: false
      t.string :password_digest
      t.string :name

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.references :company, null: false, foreign_key: true
      t.integer :department_id
      t.string :email, null: false
      t.string :password_digest
      t.string :name
      t.integer :unit_price, null: false, default: 0
      t.integer :permission, null: false, default: 0
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :discarded_at
  end
end
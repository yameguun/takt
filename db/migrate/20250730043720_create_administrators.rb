class CreateAdministrators < ActiveRecord::Migration[8.0]
  def change
    create_table :administrators do |t|
      t.string :email
      t.string :password_digest

      t.timestamps
    end
    add_index :administrators, :email, unique: true
  end
end

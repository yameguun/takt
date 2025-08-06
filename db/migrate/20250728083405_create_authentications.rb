class CreateAuthentications < ActiveRecord::Migration[8.0]
  def change
    create_table :authentications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider
      t.string :uid
      t.string :name

      t.timestamps
    end
  end
end

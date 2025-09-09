class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :phone
      t.date :birth_date
      
      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
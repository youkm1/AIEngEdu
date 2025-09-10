class CreateMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.string :membership_type, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.decimal :price, precision: 10, scale: 2
      t.string :status, default: 'active'

      t.timestamps
    end

    add_index :memberships, :membership_type
    add_index :memberships, :start_date
    add_index :memberships, :end_date
    add_index :memberships, :status
  end
end

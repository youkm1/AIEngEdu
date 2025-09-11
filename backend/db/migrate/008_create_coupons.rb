class CreateCoupons < ActiveRecord::Migration[8.0]
  def change
    create_table :coupons do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :total_uses, null: false, default: 1
      t.integer :used_count, null: false, default: 0
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :coupons, [:user_id, :expires_at]
    add_index :coupons, :expires_at
  end
end

class AddFeatureTypeToMemberships < ActiveRecord::Migration[8.0]
  def change
    add_column :memberships, :feature_type, :string, null: false, default: 'study'
    add_index :memberships, :feature_type
  end
end

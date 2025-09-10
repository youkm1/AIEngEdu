class RemoveFeatureTypeFromMemberships < ActiveRecord::Migration[8.0]
  def change
    remove_column :memberships, :feature_type, :string
  end
end

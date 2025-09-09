class MembershipPlan < ApplicationRecord
  has_many :memberships
  
  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_days, presence: true, numericality: { greater_than: 0 }
end
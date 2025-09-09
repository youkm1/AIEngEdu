class User < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :conversations, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end
class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  validates :title, presence: true

  scope :recent, -> { order(created_at: :desc) }
end

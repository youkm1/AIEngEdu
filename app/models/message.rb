class Message < ApplicationRecord
  belongs_to :conversation
  
  # Active Storage 파일 첨부
  has_one_attached :user_audio
  
  validates :role, inclusion: { in: %w[user assistant system] }
  validates :content, presence: true
  validates :audio_format, inclusion: { in: %w[wav mp3 m4a webm ogg] }, allow_blank: true
  validates :audio_duration, numericality: { greater_than: 0, less_than: 300 }, allow_blank: true # 5분 제한
  
  scope :ordered, -> { order(created_at: :asc) }
  scope :with_audio, -> { where(has_user_audio: true) }
  
  def has_audio?
    has_user_audio && user_audio.attached?
  end
  
  def audio_url
    Rails.application.routes.url_helpers.rails_blob_path(user_audio, only_path: true) if has_audio?
  end
end
class Membership < ApplicationRecord
  belongs_to :user

  validates :membership_type, inclusion: { in: %w[basic premium] }
  validates :user_id, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  
  validate :end_date_after_start_date

  scope :active, -> { where('end_date >= ?', Date.current) }
  scope :expired, -> { where('end_date < ?', Date.current) }
  scope :premium, -> { where(membership_type: 'premium') }
  scope :basic, -> { where(membership_type: 'basic') }

  private

  def end_date_after_start_date
    return unless start_date && end_date
    
    if end_date <= start_date
      errors.add(:end_date, 'must be after start date')
    end
  end
end
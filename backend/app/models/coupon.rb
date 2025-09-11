# frozen_string_literal: true

class Coupon < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :total_uses, presence: true, numericality: { greater_than: 0 }
  validates :used_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :expires_at, presence: true

  # Scopes
  scope :active, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :with_remaining_uses, -> { where('used_count < total_uses') }
  scope :exhausted, -> { where('used_count >= total_uses') }

  # 남은 사용 횟수
  def remaining_uses
    [total_uses - used_count, 0].max
  end

  # 사용 가능한지 확인
  def usable?
    active? && has_remaining_uses?
  end

  # 활성 상태인지 확인
  def active?
    expires_at > Time.current
  end

  # 남은 사용 횟수가 있는지 확인
  def has_remaining_uses?
    used_count < total_uses
  end

  # 쿠폰 사용
  def use!
    return false unless usable?

    increment!(:used_count)
    true
  end

  # 만료되었는지 확인
  def expired?
    expires_at <= Time.current
  end

  # 모든 사용 횟수를 소진했는지 확인
  def exhausted?
    used_count >= total_uses
  end

  # 상태 표시
  def status
    if expired?
      'expired'
    elsif exhausted?
      'exhausted'
    elsif usable?
      'active'
    else
      'inactive'
    end
  end
end

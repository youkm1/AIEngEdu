# frozen_string_literal: true

class User < ApplicationRecord
  has_one :membership, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :coupons, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  # 활성 멤버십이 있는지 확인
  def has_active_membership?
    membership&.active?
  end

  # 활성 멤버십 가져오기 (이제 단일 멤버십)
  def active_membership
    membership if membership&.active?
  end

  # 대화를 시작할 수 있는지 확인 (멤버십 또는 쿠폰)
  def can_start_conversation?
    has_active_membership? || has_available_coupons?
  end

  # 사용 가능한 쿠폰이 있는지 확인
  def has_available_coupons?
    coupons.active.with_remaining_uses.exists?
  end

  # 가장 오래된 사용 가능한 쿠폰 가져오기
  def next_available_coupon
    coupons.active.with_remaining_uses.order(:created_at).first
  end

  # 쿠폰 사용
  def use_coupon!
    coupon = next_available_coupon
    return false unless coupon

    coupon.use!
    coupon
  end

  # 대화 시작 처리 (멤버십 확인 후 쿠폰 사용)
  def process_conversation_start!
    # 활성 멤버십이 있으면 쿠폰 차감 없이 진행
    if has_active_membership?
      return {
        type: 'membership',
        membership: active_membership,
        message: '멤버십을 사용하여 대화를 시작합니다.'
      }
    end

    # 멤버십이 없으면 쿠폰 사용
    if has_available_coupons?
      used_coupon = use_coupon!
      if used_coupon
        return {
          type: 'coupon',
          coupon: used_coupon,
          message: '쿠폰을 사용하여 대화를 시작합니다.'
        }
      end
    end

    # 둘 다 없으면 실패
    {
      type: 'error',
      message: '활성 멤버십 또는 사용 가능한 쿠폰이 필요합니다.'
    }
  end
end

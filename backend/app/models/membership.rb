class Membership < ApplicationRecord
  # 멤버십 레벨
  LEVELS = {
    "basic" => "베이직",
    "premium" => "프리미엄"
  }.freeze

  # 멤버십별 기간 (일)
  DURATION_DAYS = {
    "basic" => 30,
    "premium" => 60
  }.freeze

  # 멤버십별 사용 가능 기능
  AVAILABLE_FEATURES = {
    "basic" => [ "study" ],
    "premium" => [ "study", "conversation", "analysis" ]
  }.freeze

  belongs_to :user

  validates :membership_type, inclusion: { in: LEVELS.keys }
  validates :user_id, presence: true, uniqueness: { scope: :status, conditions: -> { where(status: "active") }, message: "can only have one active membership" }
  validates :start_date, presence: true
  validates :end_date, presence: true

  validate :end_date_after_start_date

  scope :active, -> { where("end_date >= ? AND status = ?", Date.current, "active") }
  scope :expired, -> { where("end_date < ? OR status = ?", Date.current, "expired") }
  scope :premium, -> { where(membership_type: "premium") }
  scope :basic, -> { where(membership_type: "basic") }

  # 현재 활성화된 멤버십 확인
  def active?
    end_date >= Date.current && status == "active"
  end

  # 멤버십 설명 생성
  def description
    "#{LEVELS[membership_type]} 멤버십"
  end

  # 사용 가능한 기능 확인
  def can_use?(feature)
    AVAILABLE_FEATURES[membership_type]&.include?(feature)
  end

  # 사용 가능한 모든 기능 반환
  def available_features
    AVAILABLE_FEATURES[membership_type] || []
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end

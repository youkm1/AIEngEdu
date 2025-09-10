require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "should belong to user" do
    membership = build(:membership)
    assert_respond_to membership, :user
  end

  test "should validate membership_type inclusion" do
    membership = build(:membership, membership_type: "invalid")
    assert_not membership.valid?
    assert_includes membership.errors[:membership_type], "is not included in the list"
  end

  test "should accept basic membership type" do
    user = create(:user)
    membership = build(:membership, user: user, membership_type: "basic")
    assert membership.valid?
  end

  test "should accept premium membership type" do
    user = create(:user)
    membership = build(:membership, user: user, membership_type: "premium")
    assert membership.valid?
  end

  test "should validate end_date is after start_date" do
    membership = build(:membership,
      start_date: Date.today,
      end_date: Date.today - 1.day
    )
    assert_not membership.valid?
    assert_includes membership.errors[:end_date], "must be after start date"
  end

  test "active scope should return active memberships" do
    active = create(:membership, end_date: Date.today + 30.days)
    expired = create(:membership, :expired)

    assert_includes Membership.active, active
    assert_not_includes Membership.active, expired
  end

  test "expired scope should return expired memberships" do
    active = create(:membership, end_date: Date.today + 30.days)
    expired = create(:membership, :expired)

    assert_includes Membership.expired, expired
    assert_not_includes Membership.expired, active
  end

  test "premium scope should return only premium memberships" do
    premium = create(:membership, :premium)
    basic = create(:membership, :basic)

    assert_includes Membership.premium, premium
    assert_not_includes Membership.premium, basic
  end
end

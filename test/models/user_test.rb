require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should not save user without email" do
    user = build(:user, email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should not save user without name" do
    user = build(:user, name: nil)
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "should not allow duplicate emails" do
    existing_user = create(:user)
    duplicate_user = build(:user, email: existing_user.email)
    
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "should have many memberships" do
    user = create(:user)
    membership1 = create(:membership, user: user)
    membership2 = create(:membership, user: user)
    
    assert_equal 2, user.memberships.count
    assert_includes user.memberships, membership1
    assert_includes user.memberships, membership2
  end

  test "should destroy associated memberships when user is destroyed" do
    user = create(:user)
    create(:membership, user: user)
    
    assert_difference("Membership.count", -1) do
      user.destroy
    end
  end

  test "should have many conversations" do
    user = create(:user)
    conversation = create(:conversation, user: user)
    
    assert_includes user.conversations, conversation
  end
end
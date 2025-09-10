# Mutation Testing - 코드를 의도적으로 변경해서 테스트의 견고함 검증
# 실제로는 mutant gem을 사용하지만, 수동으로 시뮬레이션

require "test_helper"

class MembershipModelMutationTest < ActiveSupport::TestCase
  # 뮤테이션 테스트: 코드 변경 시 테스트가 실패하는지 확인

  test "should detect changes in membership validation logic" do
    user = User.create!(email: "mutation@example.com", name: "Mutation User")

    # 정상 케이스
    valid_membership = user.memberships.build(
      membership_type: "basic",
      start_date: Date.current,
      end_date: Date.current + 30.days,
      price: 49000,
      status: "active"
    )
    assert valid_membership.valid?

    # Mutation 1: membership_type 검증 제거 시뮬레이션
    invalid_type_membership = user.memberships.build(
      membership_type: "invalid_type",  # 잘못된 타입
      start_date: Date.current,
      end_date: Date.current + 30.days,
      price: 49000,
      status: "active"
    )

    # 이 테스트가 실패하면 validation이 제대로 작동하지 않음
    refute invalid_type_membership.valid?,
      "Should detect invalid membership type - mutation test failed!"
    assert_includes invalid_type_membership.errors[:membership_type],
      "is not included in the list"

    # Mutation 2: 날짜 검증 로직 변경 시뮬레이션
    invalid_date_membership = user.memberships.build(
      membership_type: "basic",
      start_date: Date.current,
      end_date: Date.current - 1.day,  # 잘못된 날짜 (과거)
      price: 49000,
      status: "active"
    )

    refute invalid_date_membership.valid?,
      "Should detect invalid end date - mutation test failed!"
    assert_includes invalid_date_membership.errors[:end_date],
      "must be after start date"
  end

  test "should detect changes in business logic" do
    user = User.create!(email: "business@example.com", name: "Business User")

    # Mutation 3: can_use? 메서드 로직 변경 시뮬레이션
    basic_membership = user.memberships.create!(
      membership_type: "basic",
      start_date: Date.current,
      end_date: Date.current + 30.days,
      price: 49000,
      status: "active"
    )

    premium_membership = user.memberships.create!(
      membership_type: "premium",
      start_date: Date.current,
      end_date: Date.current + 60.days,
      price: 99000,
      status: "expired"  # 만료 상태
    )

    # Basic 멤버십 권한 검증
    assert basic_membership.can_use?("study"),
      "Basic should allow study - mutation test failed!"
    refute basic_membership.can_use?("conversation"),
      "Basic should not allow conversation - mutation test failed!"
    refute basic_membership.can_use?("analysis"),
      "Basic should not allow analysis - mutation test failed!"

    # Premium 멤버십 권한 검증 (만료되었지만 can_use?는 타입만 체크)
    assert premium_membership.can_use?("study"),
      "Premium should allow study - mutation test failed!"
    assert premium_membership.can_use?("conversation"),
      "Premium should allow conversation - mutation test failed!"
    assert premium_membership.can_use?("analysis"),
      "Premium should allow analysis - mutation test failed!"
  end
end

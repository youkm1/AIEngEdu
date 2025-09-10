require "test_helper"

class MembershipPropertiesTest < ActiveSupport::TestCase
  # Property-Based Testing - 다양한 입력값으로 불변 조건 검증

  test "membership end date should always be after start date" do
    100.times do
      # Given: 랜덤 파라미터
      membership_type = [ "basic", "premium" ].sample
      start_date = Date.current - rand(30).days

      user = User.create!(
        email: "prop_#{SecureRandom.hex(4)}@example.com",
        name: "Property User"
      )

      # When: 멤버십 생성
      membership = user.memberships.create!(
        membership_type: membership_type,
        start_date: start_date,
        end_date: start_date + Membership::DURATION_DAYS[membership_type].days,
        price: membership_type == "premium" ? 99000 : 49000,
        status: "active"
      )

      # Then: 불변 조건 - 종료일이 항상 시작일 이후
      assert membership.end_date > membership.start_date,
        "End date (#{membership.end_date}) should be after start date (#{membership.start_date})"

      # 추가 불변 조건들
      assert membership.price >= 0, "Price should not be negative"
      assert [ "basic", "premium" ].include?(membership.membership_type),
        "Invalid membership type: #{membership.membership_type}"
      assert membership.available_features.is_a?(Array),
        "Available features should be an array"
      assert membership.available_features.include?("study"),
        "All memberships should include study feature"
    end
  end

  test "payment calculations should be consistent regardless of input order" do
    amounts = [ 49000, 99000, 129000, 199000 ]

    amounts.each do |amount|
      10.times do
        # Property: VAT 계산의 일관성
        result = MockTossPaymentsService.confirm_payment(
          payment_key: SecureRandom.hex(8),
          order_id: "ORDER-PROP-#{rand(1000)}",
          amount: amount
        )

        # 불변 조건: 공급가 + VAT = 총액
        total_calculated = result[:suppliedAmount] + result[:vat]
        assert_equal amount, total_calculated,
          "Supply amount + VAT should equal total amount"

        # 불변 조건: VAT는 항상 양수
        assert result[:vat] >= 0, "VAT should not be negative"

        # 불변 조건: 공급가는 총액보다 작거나 같음
        assert result[:suppliedAmount] <= amount,
          "Supply amount should not exceed total amount"
      end
    end
  end
end

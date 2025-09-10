require "test_helper"

class MembershipPaymentFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "test@example.com",
      name: "테스트 사용자"
    )
    @admin_user = User.create!(
      email: "admin@ringle.com",
      name: "관리자"
    )
  end

  # ========== 전체 결제 플로우 통합 테스트 ==========

  test "complete membership payment flow should work end-to-end" do
    # Step 1: 결제 준비
    post api_payments_prepare_path, params: {
      user_id: @user.id,
      membership_type: "premium"
    }

    assert_response :success
    prepare_data = json_response[:data]
    order_id = prepare_data[:orderId]
    amount = prepare_data[:amount]

    assert_equal 99000, amount
    assert_includes order_id, "PREMIUM"
    assert_not_nil prepare_data[:clientKey]

    # Step 2: Mock 결제 진행 (실제로는 프론트엔드에서)
    payment_key = "PAYMENT-#{SecureRandom.hex(8).upcase}"

    # Step 3: 결제 승인
    post api_payments_confirm_path, params: {
      user_id: @user.id,
      paymentKey: payment_key,
      orderId: order_id,
      amount: amount
    }

    assert_response :success
    confirm_data = json_response[:data]

    # Payment 응답 검증
    assert_equal "DONE", confirm_data[:payment][:status]
    assert_equal payment_key, confirm_data[:payment][:paymentKey]

    # Membership 생성 검증
    membership = confirm_data[:membership]
    assert_equal "premium", membership[:membership_type]
    assert_equal "프리미엄", membership[:membership_level]
    assert_equal [ "study", "conversation", "analysis" ], membership[:available_features]

    # DB 상태 검증
    @user.reload
    active_membership = @user.memberships.active.first
    assert_not_nil active_membership
    assert_equal "premium", active_membership.membership_type
    assert_equal Date.current + 60.days, active_membership.end_date
    assert active_membership.can_use?("conversation")
    assert active_membership.can_use?("analysis")
  end

  test "should handle membership upgrade flow" do
    # Given: 기존 Basic 멤버십이 있는 사용자
    existing_membership = create_basic_membership(@user)
    assert_equal "active", existing_membership.status

    # When: Premium으로 업그레이드
    post api_payments_prepare_path, params: {
      user_id: @user.id,
      membership_type: "premium"
    }

    prepare_data = json_response[:data]

    post api_payments_confirm_path, params: {
      user_id: @user.id,
      paymentKey: "PAYMENT-UPGRADE-#{SecureRandom.hex(4)}",
      orderId: prepare_data[:orderId],
      amount: 99000
    }

    # Then: 기존 멤버십 만료, 새 프리미엄 멤버십 활성
    assert_response :success

    existing_membership.reload
    assert_equal "expired", existing_membership.status

    new_membership = @user.reload.memberships.active.first
    assert_equal "premium", new_membership.membership_type
    assert_equal "active", new_membership.status

    # 권한 검증
    assert new_membership.can_use?("study")
    assert new_membership.can_use?("conversation")
    assert new_membership.can_use?("analysis")
  end

  # ========== 관리자 워크플로우 통합 테스트 ==========

  test "admin workflow should manage memberships properly" do
    target_user = User.create!(email: "target@example.com", name: "대상자")

    # Step 1: 관리자가 멤버십 부여
    post api_admin_memberships_assign_path, params: {
      admin_user_id: @admin_user.id,
      user_id: target_user.id,
      membership_type: "basic",
      price: 0  # 관리자 부여시 무료
    }

    assert_response :created
    membership_data = json_response[:data]
    membership_id = membership_data[:id]

    # Step 2: 멤버십 목록 조회
    get api_admin_memberships_path, params: {
      admin_user_id: @admin_user.id
    }

    assert_response :success
    memberships = json_response
    assert memberships.any? { |m| m[:id] == membership_id }

    # Step 3: 특정 사용자 멤버십 조회
    get api_user_memberships_path(target_user), params: {
      user_id: target_user.id
    }

    assert_response :success
    user_memberships = json_response
    assert_equal 1, user_memberships.length
    assert_equal "basic", user_memberships.first[:membership_type]

    # Step 4: 멤버십 삭제
    delete api_admin_membership_path(membership_id), params: {
      admin_user_id: @admin_user.id
    }

    assert_response :success

    # 삭제 확인
    assert_raises(ActiveRecord::RecordNotFound) do
      Membership.find(membership_id)
    end
  end

  # ========== 에러 시나리오 통합 테스트 ==========

  test "should handle payment failure gracefully" do
    # Step 1: 정상 결제 준비
    post api_payments_prepare_path, params: {
      user_id: @user.id,
      membership_type: "basic"
    }

    prepare_data = json_response[:data]

    # Step 2: 잘못된 금액으로 결제 승인 시도
    post api_payments_confirm_path, params: {
      user_id: @user.id,
      paymentKey: "INVALID-PAYMENT",
      orderId: prepare_data[:orderId],
      amount: 10000  # 잘못된 금액 (49000이어야 함)
    }

    # Then: 결제 실패
    assert_response :unprocessable_entity
    assert_json_error_response("결제 금액이 일치하지 않습니다")

    # 멤버십이 생성되지 않았는지 확인
    assert_equal 0, @user.memberships.count
  end

  test "should prevent unauthorized admin access" do
    regular_user = User.create!(email: "regular@example.com", name: "일반 사용자")

    # When: 일반 사용자가 관리자 API 접근 시도
    post api_admin_memberships_assign_path, params: {
      admin_user_id: regular_user.id,  # 관리자가 아닌 사용자
      user_id: @user.id,
      membership_type: "premium"
    }

    # Then: 접근 거부
    assert_response :forbidden
    assert_json_error_response("관리자 권한이 필요합니다")
  end

  # ========== 동시성 및 경계 조건 테스트 ==========

  test "should handle concurrent membership operations" do
    # 동일 사용자에 대한 여러 멤버십 생성 시도
    threads = []

    3.times do |i|
      threads << Thread.new do
        post api_payments_confirm_path, params: {
          user_id: @user.id,
          paymentKey: "CONCURRENT-#{i}",
          orderId: "ORDER-BASIC-#{Time.current.to_i}-#{i}",
          amount: 49000
        }
      end
    end

    threads.each(&:join)

    # 결과: 하나의 활성 멤버십만 존재해야 함
    @user.reload
    active_memberships = @user.memberships.active
    assert_equal 1, active_memberships.count
  end

  # ========== 성능 테스트 ==========

  test "membership operations should be performant" do
    # 대량 데이터 생성
    users = []
    50.times do |i|
      users << User.create!(
        email: "perf_user_#{i}@example.com",
        name: "Performance User #{i}"
      )
    end

    # 대량 멤버십 생성 시간 측정
    start_time = Time.current

    users.each do |user|
      create_basic_membership(user)
    end

    end_time = Time.current
    execution_time = end_time - start_time

    # 성능 검증 (50개 멤버십 생성이 5초 이내)
    assert execution_time < 5.0, "Membership creation took too long: #{execution_time}s"

    # 대량 조회 성능 테스트
    start_time = Time.current

    get api_admin_memberships_path, params: {
      admin_user_id: @admin_user.id
    }

    end_time = Time.current
    query_time = end_time - start_time

    assert_response :success
    assert query_time < 1.0, "Membership query took too long: #{query_time}s"
  end
end

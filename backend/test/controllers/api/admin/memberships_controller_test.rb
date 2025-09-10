require "test_helper"

class Api::Admin::MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = User.create!(
      email: "admin@ringle.com",
      name: "관리자"
    )
    @regular_user = User.create!(
      email: "user@example.com",
      name: "일반 사용자"
    )
    @target_user = User.create!(
      email: "target@example.com",
      name: "대상 사용자"
    )
  end

  # ========== 인증/인가 테스트 ==========

  test "should require admin authentication for all actions" do
    # Given: 인증 없이 요청
    # When: Admin API 호출
    post assign_api_admin_memberships_path

    # Then: 403 Forbidden
    assert_response :forbidden
    assert_json_error_response("관리자 권한이 필요합니다")
  end

  test "should reject non-admin user access" do
    # Given: 일반 사용자로 인증
    # When: Admin API 호출
    post assign_api_admin_memberships_path, params: {
      admin_user_id: @regular_user.id,
      user_id: @target_user.id,
      membership_type: "premium"
    }

    # Then: 403 Forbidden
    assert_response :forbidden
    assert_json_error_response("관리자 권한이 필요합니다")
  end

  test "should allow admin user access" do
    # Given: Admin 사용자로 인증
    # When: Admin API 호출
    post assign_api_admin_memberships_path, params: {
      admin_user_id: @admin_user.id,
      user_id: @target_user.id,
      membership_type: "basic"
    }

    # Then: 성공 응답
    assert_response :created
    assert_json_success_response("멤버십이 성공적으로 부여되었습니다")
  end

  # ========== 멤버십 부여 테스트 ==========

  test "should assign basic membership successfully" do
    # Given: 멤버십이 없는 사용자
    assert_equal 0, @target_user.memberships.count

    # When: Basic 멤버십 부여
    post assign_api_admin_memberships_path, params: {
      admin_user_id: @admin_user.id,
      user_id: @target_user.id,
      membership_type: "basic",
      start_date: Date.current.to_s,
      price: 49000
    }

    # Then: 멤버십 생성 및 올바른 속성
    assert_response :created

    membership = @target_user.reload.memberships.active.first
    assert_not_nil membership
    assert_equal "basic", membership.membership_type
    assert_equal 49000, membership.price
    assert_equal Date.current + 30.days, membership.end_date
    assert_equal [ "study" ], membership.available_features

    # JSON 응답 검증
    response_data = json_response[:data]
    assert_equal "basic", response_data[:membership_type]
    assert_equal "베이직", response_data[:membership_level]
    assert_equal [ "study" ], response_data[:available_features]
  end

  test "should assign premium membership successfully" do
    # Given: 멤버십이 없는 사용자
    # When: Premium 멤버십 부여
    post assign_api_admin_memberships_path, params: {
      admin_user_id: @admin_user.id,
      user_id: @target_user.id,
      membership_type: "premium"
    }

    # Then: Premium 멤버십 생성
    assert_response :created

    membership = @target_user.reload.memberships.active.first
    assert_equal "premium", membership.membership_type
    assert_equal Date.current + 60.days, membership.end_date
    assert_equal [ "study", "conversation", "analysis" ], membership.available_features
  end

  test "should expire existing membership when assigning new one" do
    # Given: 기존 활성 멤버십이 있는 사용자
    existing_membership = @target_user.memberships.create!(
      membership_type: "basic",
      start_date: Date.current - 10.days,
      end_date: Date.current + 20.days,
      price: 49000,
      status: "active"
    )

    assert_equal "active", existing_membership.status

    # When: 새로운 멤버십 부여
    post assign_api_admin_memberships_path, params: {
      admin_user_id: @admin_user.id,
      user_id: @target_user.id,
      membership_type: "premium"
    }

    # Then: 기존 멤버십은 만료, 새 멤버십은 활성
    assert_response :created

    existing_membership.reload
    assert_equal "expired", existing_membership.status

    new_membership = @target_user.memberships.active.first
    assert_equal "premium", new_membership.membership_type
    assert_equal "active", new_membership.status
  end

  # ========== 유효성 검증 테스트 ==========

  test "should validate membership_type parameter" do
    # When: 잘못된 멤버십 타입으로 요청
    post assign_api_admin_memberships_path, params: {
      admin_user_id: @admin_user.id,
      user_id: @target_user.id,
      membership_type: "invalid_type"
    }

    # Then: 유효성 검증 실패
    assert_response :unprocessable_entity
    assert_json_error_response("멤버십 부여에 실패했습니다")
    assert_includes json_response[:errors], "Membership type is not included in the list"
  end

  test "should validate user existence" do
    # When: 존재하지 않는 사용자에게 멤버십 부여
    post assign_api_admin_memberships_path, params: {
      admin_user_id: @admin_user.id,
      user_id: 99999,
      membership_type: "basic"
    }
    
    # Then: 404 Not Found 응답
    assert_response :not_found
    assert_json_error_response("요청한 리소스를 찾을 수 없습니다")
  end

  # ========== 멤버십 삭제 테스트 ==========

  test "should delete membership successfully" do
    # Given: 활성 멤버십이 있는 사용자
    membership = @target_user.memberships.create!(
      membership_type: "basic",
      start_date: Date.current,
      end_date: Date.current + 30.days,
      price: 49000,
      status: "active"
    )

    # When: 멤버십 삭제
    delete api_admin_membership_path(membership), params: {
      admin_user_id: @admin_user.id
    }

    # Then: 멤버십 삭제됨
    assert_response :success
    assert_json_success_response("멤버십이 삭제되었습니다")

    assert_raises(ActiveRecord::RecordNotFound) do
      membership.reload
    end
  end

  # ========== 멤버십 목록 조회 테스트 ==========

  test "should list all memberships" do
    # Given: 여러 멤버십이 존재
    create_sample_memberships

    # When: 전체 멤버십 조회
    get api_admin_memberships_path, params: {
      admin_user_id: @admin_user.id
    }

    # Then: 모든 멤버십 반환
    assert_response :success
    memberships = json_response
    assert_equal 3, memberships.length
  end

  test "should filter memberships by status" do
    # Given: 다양한 상태의 멤버십
    create_sample_memberships

    # When: active 상태만 필터링
    get api_admin_memberships_path, params: {
      admin_user_id: @admin_user.id,
      status: "active"
    }

    # Then: active 멤버십만 반환
    assert_response :success
    memberships = json_response
    assert_equal 2, memberships.length
    memberships.each do |membership|
      assert_equal "active", membership[:status]
    end
  end

  test "should filter memberships by type" do
    # Given: 다양한 타입의 멤버십
    create_sample_memberships

    # When: premium 타입만 필터링
    get api_admin_memberships_path, params: {
      admin_user_id: @admin_user.id,
      type: "premium"
    }

    # Then: premium 멤버십만 반환
    assert_response :success
    memberships = json_response
    assert_equal 1, memberships.length
    assert_equal "premium", memberships.first[:membership_type]
  end

  # ========== Edge Cases 테스트 ==========

  test "should handle concurrent membership assignments gracefully" do
    # 동시성 테스트는 실제 환경에서는 더 복잡하지만, 기본 로직 테스트
    # Given: 사용자
    # When: 연속으로 멤버십 할당
    2.times do
      post assign_api_admin_memberships_path, params: {
        admin_user_id: @admin_user.id,
        user_id: @target_user.id,
        membership_type: "premium"
      }
    end

    # Then: 하나의 활성 멤버십만 존재
    active_memberships = @target_user.reload.memberships.active
    assert_equal 1, active_memberships.count
  end

  # 헬퍼 메서드들은 test/support/에 모듈화되어 있음
end

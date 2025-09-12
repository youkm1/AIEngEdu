class Api::PaymentsController < ApplicationController
  include MembershipJsonHelper
  include ErrorHandler

  skip_before_action :verify_authenticity_token

  # POST /api/payments/prepare
  # 결제 준비 - 프론트엔드에서 결제 위젯을 띄우기 위한 정보 제공
  def prepare
    set_user
    membership_type = params[:membership_type]

    # 가격 계산
    price = membership_type == "premium" ? 99000 : 49000
    order_id = generate_order_id(membership_type)
    order_name = membership_type == "premium" ? "프리미엄 멤버십 (60일)" : "베이직 멤버십 (30일)"

    # Mock 클라이언트 키 생성 (실제로는 토스에서 발급)
    client_key = "test_ck_#{SecureRandom.hex(20)}"

    render json: success_json(
      message: "결제 준비가 완료되었습니다",
      data: {
        clientKey: client_key,
        orderId: order_id,
        orderName: order_name,
        amount: price,
        customerName: @user&.name || "Test User",
        customerEmail: @user&.email || "test@example.com",
        successUrl: "#{request.base_url}/api/payments/success",
        failUrl: "#{request.base_url}/api/payments/fail"
      }
    )
  end

  # POST /api/payments/confirm
  # 결제 승인 - 프론트엔드에서 결제 완료 후 호출
  def confirm
    set_user
    payment_key = params[:paymentKey] || params[:payment_key] || generate_payment_key
    order_id = params[:orderId] || params[:order_id]
    amount = params[:amount]

    # order_id에서 membership_type 추출
    membership_type = extract_membership_type(order_id)
    price = membership_type == "premium" ? 99000 : 49000

    # 금액 검증
    if amount.to_i != price
      return render json: error_json(
        message: "결제 금액이 일치하지 않습니다"
      ), status: :unprocessable_entity
    end

    # Mock PG사 결제 승인 요청
    payment_result = MockTossPaymentsService.confirm_payment(
      payment_key: payment_key,
      order_id: order_id,
      amount: price
    )

    if payment_result[:status] == "DONE"
      # 결제 성공 시 멤버십 생성
      create_membership_after_payment(membership_type, price, payment_result)

      render json: success_json(
        message: "결제가 성공적으로 완료되었습니다",
        data: {
          payment: payment_result,
          membership: membership_json(@membership)
        }
      )
    else
      # 결제 실패 시
      render json: error_json(
        message: "결제 처리 중 오류가 발생했습니다",
        errors: [ payment_result ]
      ), status: :unprocessable_entity
    end
  end

  # POST /api/payments/cancel
  # 결제 취소
  def cancel
    set_user
    payment_key = params[:payment_key]
    cancel_reason = params[:cancel_reason] || "고객 요청"

    # 해당 결제로 생성된 멤버십 찾기
    membership = @user.membership

    unless membership&.active?
      return render json: {
        success: false,
        message: "취소할 활성 멤버십이 없습니다"
      }, status: :not_found
    end

    # Mock PG사 결제 취소 요청
    cancel_result = MockTossPaymentsService.cancel_payment(
      payment_key: payment_key,
      cancel_reason: cancel_reason,
      cancel_amount: membership.price
    )

    if cancel_result[:status] == "CANCELED"
      # 멤버십 취소 처리
      membership.update!(status: "canceled")

      render json: {
        success: true,
        message: "결제가 성공적으로 취소되었습니다",
        payment: cancel_result,
        membership_id: membership.id
      }
    else
      render json: {
        success: false,
        message: "결제 취소 중 오류가 발생했습니다",
        error: cancel_result
      }, status: :unprocessable_entity
    end
  rescue => e
    render json: {
      success: false,
      message: "결제 취소 중 오류가 발생했습니다",
      error: e.message
    }, status: :internal_server_error
  end

  # GET /api/payments/:payment_key
  # 결제 조회
  def show
    payment_key = params[:payment_key]

    payment_info = MockTossPaymentsService.get_payment(payment_key: payment_key)

    render json: {
      success: true,
      payment: payment_info
    }
  rescue => e
    render json: {
      success: false,
      message: "결제 정보 조회 중 오류가 발생했습니다",
      error: e.message
    }, status: :internal_server_error
  end

  # GET /api/payments/success
  # 결제 성공 페이지 (프론트엔드 리다이렉트)
  def success
    render json: {
      success: true,
      message: "결제가 성공적으로 처리되었습니다. 결제 승인을 진행해주세요.",
      paymentKey: params[:paymentKey],
      orderId: params[:orderId],
      amount: params[:amount]
    }
  end

  # GET /api/payments/fail
  # 결제 실패 페이지 (프론트엔드 리다이렉트)
  def fail
    render json: {
      success: false,
      message: params[:message] || "결제가 실패했습니다",
      code: params[:code]
    }, status: :payment_required
  end

  # POST /api/payments/webhook
  # Mock 웹훅 - PG사에서 결제 상태 변경 시 호출하는 것을 시뮬레이션
  def webhook
    event_type = params[:eventType]
    payment_key = params[:data][:paymentKey] if params[:data]

    case event_type
    when "PAYMENT_STATUS_CHANGED"
      # 결제 상태 변경 처리
      Rails.logger.info "Payment status changed: #{payment_key}"
    when "PAYMENT_CANCELED"
      # 결제 취소 처리
      Rails.logger.info "Payment canceled: #{payment_key}"
    end

    render json: { received: true }, status: :ok
  end

  # POST /api/payments/simulate_failure
  # 테스트용: 결제 실패 시뮬레이션
  def simulate_failure
    error_code = params[:error_code] || "INVALID_CARD_NUMBER"

    error_result = MockTossPaymentsService.simulate_payment_failure(error_code: error_code)

    render json: {
      success: false,
      message: "결제가 실패했습니다",
      error: error_result
    }, status: :payment_required
  end

  private

  def set_user
    @user = User.find_by(id: params[:user_id]) || User.first # 인증 로직 없이 간단히 처리
  end

  def generate_payment_key
    "PAYMENT-#{SecureRandom.hex(16).upcase}"
  end

  def generate_order_id(membership_type)
    type_prefix = membership_type.upcase
    timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    "ORDER-#{type_prefix}-#{timestamp}-#{SecureRandom.hex(4).upcase}"
  end

  def extract_membership_type(order_id)
    return nil unless order_id

    if order_id.include?("PREMIUM")
      "premium"
    elsif order_id.include?("BASIC")
      "basic"
    else
      "basic" # 기본값
    end
  end

  def create_membership_after_payment(membership_type, price, payment_result)
    # 기존 멤버십 삭제
    @user.membership&.destroy

    # 새 멤버십 생성
    @membership = @user.create_membership!(
      membership_type: membership_type,
      start_date: Date.current,
      end_date: Date.current + Membership::DURATION_DAYS[membership_type].days,
      price: price,
      status: "active"
    )

    # 결제 정보 저장 (필요 시 별도 Payment 모델 생성 가능)
    @membership.update!(
      payment_key: payment_result[:paymentKey],
      order_id: payment_result[:orderId]
    ) if @membership.respond_to?(:payment_key)
  end

  # membership_json 메서드는 MembershipJsonHelper에서 제공
end

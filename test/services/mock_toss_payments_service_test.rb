require "test_helper"

class MockTossPaymentsServiceTest < ActiveSupport::TestCase
  # ========== 결제 승인 테스트 ==========
  
  test "should confirm payment with valid data" do
    # Given: 결제 파라미터
    payment_key = "test_payment_key"
    order_id = "ORDER-PREMIUM-123"
    amount = 99000
    
    # When: 결제 승인
    result = MockTossPaymentsService.confirm_payment(
      payment_key: payment_key,
      order_id: order_id,
      amount: amount
    )
    
    # Then: 성공 응답 구조 검증
    assert_equal "DONE", result[:status]
    assert_equal payment_key, result[:paymentKey]
    assert_equal order_id, result[:orderId]
    assert_equal amount, result[:totalAmount]
    assert_equal "KRW", result[:currency]
    assert_equal "프리미엄 멤버십 (60일)", result[:orderName]
    
    # 카드 정보 구조 검증
    assert_not_nil result[:card]
    assert_equal amount, result[:card][:amount]
    assert_match /\d{6}\*{6}\d{4}/, result[:card][:number]
    
    # 영수증 URL 검증
    assert_not_nil result[:receipt][:url]
    assert_includes result[:receipt][:url], payment_key
  end
  
  test "should generate different payment keys for different requests" do
    # When: 여러 번 결제 승인
    result1 = MockTossPaymentsService.confirm_payment(
      payment_key: "key1", order_id: "order1", amount: 1000
    )
    result2 = MockTossPaymentsService.confirm_payment(
      payment_key: "key2", order_id: "order2", amount: 2000  
    )
    
    # Then: 각각 다른 결과
    assert_not_equal result1[:lastTransactionKey], result2[:lastTransactionKey]
    assert_not_equal result1[:paymentKey], result2[:paymentKey]
  end
  
  # ========== 결제 취소 테스트 ==========
  
  test "should cancel payment successfully" do
    # Given: 취소 파라미터
    payment_key = "test_payment_key"
    cancel_reason = "고객 요청"
    cancel_amount = 99000
    
    # When: 결제 취소
    result = MockTossPaymentsService.cancel_payment(
      payment_key: payment_key,
      cancel_reason: cancel_reason,
      cancel_amount: cancel_amount
    )
    
    # Then: 취소 성공 응답
    assert_equal "CANCELED", result[:status]
    assert_equal payment_key, result[:paymentKey]
    assert_equal 0, result[:totalAmount]
    assert_equal 0, result[:balanceAmount]
    
    # 취소 내역 검증
    cancel_info = result[:cancels].first
    assert_equal cancel_amount, cancel_info[:cancelAmount]
    assert_equal cancel_reason, cancel_info[:cancelReason]
    assert_equal "DONE", cancel_info[:cancelStatus]
    assert_not_nil cancel_info[:canceledAt]
  end
  
  # ========== 결제 조회 테스트 ==========
  
  test "should get payment info" do
    # Given: 결제 키
    payment_key = "test_payment_key"
    
    # When: 결제 조회
    result = MockTossPaymentsService.get_payment(payment_key: payment_key)
    
    # Then: 결제 정보 반환
    assert_equal payment_key, result[:paymentKey]
    assert_equal "DONE", result[:status]
    assert_equal "멤버십 결제", result[:orderName]
    assert_equal 99000, result[:totalAmount]
    assert_not_nil result[:card]
  end
  
  # ========== 에러 시뮬레이션 테스트 ==========
  
  test "should simulate payment failure with error codes" do
    error_codes = [
      "INVALID_CARD_NUMBER",
      "INVALID_CARD_EXPIRY", 
      "INSUFFICIENT_BALANCE",
      "EXCEED_MAX_AMOUNT",
      "REJECTED_CARD"
    ]
    
    error_codes.each do |error_code|
      # When: 에러 시뮬레이션
      result = MockTossPaymentsService.simulate_payment_failure(error_code: error_code)
      
      # Then: 에러 응답 구조 검증
      assert_equal error_code, result[:code]
      assert_not_nil result[:message]
      assert_not_nil result[:timestamp]
      
      # 에러 메시지가 적절한지 검증
      case error_code
      when "INVALID_CARD_NUMBER"
        assert_includes result[:message], "카드 번호"
      when "INSUFFICIENT_BALANCE"
        assert_includes result[:message], "잔액"
      end
    end
  end
  
  # ========== 비즈니스 로직 테스트 ==========
  
  test "should calculate VAT correctly" do
    # Given: 결제 금액
    amount = 110000
    
    # When: 결제 승인
    result = MockTossPaymentsService.confirm_payment(
      payment_key: "test", order_id: "test", amount: amount
    )
    
    # Then: VAT 계산 검증 (부가세 10%)
    expected_supplied = (amount / 1.1).round
    expected_vat = amount - expected_supplied
    
    assert_equal expected_supplied, result[:suppliedAmount]
    assert_equal expected_vat, result[:vat]
    assert_equal amount, result[:totalAmount]
  end
  
  test "should generate proper order names based on order_id" do
    test_cases = [
      { order_id: "ORDER-PREMIUM-123", expected: "프리미엄 멤버십 (60일)" },
      { order_id: "ORDER-BASIC-456", expected: "베이직 멤버십 (30일)" },
      { order_id: "ORDER-UNKNOWN-789", expected: "멤버십 결제" }
    ]
    
    test_cases.each do |test_case|
      result = MockTossPaymentsService.confirm_payment(
        payment_key: "test",
        order_id: test_case[:order_id],
        amount: 1000
      )
      
      assert_equal test_case[:expected], result[:orderName]
    end
  end
end
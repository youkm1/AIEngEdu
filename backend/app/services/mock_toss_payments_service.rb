class MockTossPaymentsService
  # 토스 페이먼츠 API를 모방한 Mock 서비스
  # 실제 결제 없이 토스 페이먼츠 응답 형태만 모방
  # 모든 URL은 가짜이며 실제 토스 페이먼츠 API를 호출하지 않음

  class << self
    # 결제 승인 요청 (토스 페이먼츠 /v1/payments/confirm 모방)
    def confirm_payment(payment_key:, order_id:, amount:)
      # Mock 결제 성공 응답
      {
        mId: "tosspayments",
        lastTransactionKey: "#{SecureRandom.hex(16).upcase}",
        paymentKey: payment_key,
        orderId: order_id,
        orderName: get_order_name(order_id),
        taxExemptionAmount: 0,
        status: "DONE",
        requestedAt: Time.current.iso8601,
        approvedAt: Time.current.iso8601,
        useEscrow: false,
        cultureExpense: false,
        card: mock_card_info,
        virtualAccount: nil,
        transfer: nil,
        mobilePhone: nil,
        giftCertificate: nil,
        cashReceipt: nil,
        cashReceipts: nil,
        discount: nil,
        cancels: nil,
        secret: nil,
        type: "NORMAL",
        easyPay: {
          provider: "토스페이",
          amount: amount,
          discountAmount: 0
        },
        country: "KR",
        failure: nil,
        isPartialCancelable: true,
        receipt: {
          # 실제 토스 연동 api 연결 확장을 고려하여 url 설계
          url: "https://mock-payments.ringle.com/receipt/#{payment_key}"
        },
        checkout: {
          url: "https://mock-payments.ringle.com/checkout/#{payment_key}"
        },
        currency: "KRW",
        totalAmount: amount,
        balanceAmount: amount,
        suppliedAmount: (amount / 1.1).round,
        vat: amount - (amount / 1.1).round,
        taxFreeAmount: 0,
        method: "카드",
        version: "2022-11-16"
      }
    end

    # 결제 취소 요청 (토스 페이먼츠 /v1/payments/{paymentKey}/cancel 모방)
    def cancel_payment(payment_key:, cancel_reason:, cancel_amount: nil)
      # Mock 결제 취소 응답
      {
        mId: "tosspayments",
        lastTransactionKey: "#{SecureRandom.hex(16).upcase}",
        paymentKey: payment_key,
        orderId: "ORDER-#{SecureRandom.hex(8)}",
        orderName: "멤버십 결제 취소",
        status: "CANCELED",
        requestedAt: Time.current.iso8601,
        approvedAt: (Time.current - 1.hour).iso8601,
        useEscrow: false,
        cultureExpense: false,
        card: mock_card_info,
        cancels: [
          {
            cancelAmount: cancel_amount || 99000,
            cancelReason: cancel_reason,
            taxFreeAmount: 0,
            taxExemptionAmount: 0,
            refundableAmount: cancel_amount || 99000,
            easyPayDiscountAmount: 0,
            canceledAt: Time.current.iso8601,
            transactionKey: "#{SecureRandom.hex(16).upcase}",
            receiptKey: nil,
            cancelStatus: "DONE",
            cancelRequestId: nil
          }
        ],
        isPartialCancelable: true,
        receipt: {
          url: "https://mock-payments.ringle.com/receipt/#{payment_key}"
        },
        checkout: {
          url: "https://mock-payments.ringle.com/checkout/#{payment_key}"
        },
        currency: "KRW",
        totalAmount: 0,
        balanceAmount: 0,
        suppliedAmount: 0,
        vat: 0,
        taxFreeAmount: 0,
        method: "카드",
        version: "2022-11-16"
      }
    end

    # 결제 조회 (토스 페이먼츠 /v1/payments/{paymentKey} 모방)
    def get_payment(payment_key:)
      {
        mId: "tosspayments",
        paymentKey: payment_key,
        orderId: "ORDER-#{SecureRandom.hex(8)}",
        orderName: "멤버십 결제",
        status: "DONE",
        requestedAt: Time.current.iso8601,
        approvedAt: Time.current.iso8601,
        card: mock_card_info,
        totalAmount: 99000,
        method: "카드",
        version: "2022-11-16"
      }
    end

    # 결제 실패 시뮬레이션 (테스트용)
    def simulate_payment_failure(error_code: "INVALID_CARD_NUMBER")
      {
        code: error_code,
        message: get_error_message(error_code),
        timestamp: Time.current.iso8601
      }
    end

    private

    def mock_card_info
      {
        amount: 99000,
        issuerCode: "4V",
        acquirerCode: "3K",
        number: "433012******1234",
        installmentPlanMonths: 0,
        approveNo: "00000000",
        useCardPoint: false,
        cardType: "신용",
        ownerType: "개인",
        acquireStatus: "READY",
        isInterestFree: false,
        interestPayer: nil
      }
    end

    def get_order_name(order_id)
      if order_id.include?("PREMIUM")
        "프리미엄 멤버십 (60일)"
      elsif order_id.include?("BASIC")
        "베이직 멤버십 (30일)"
      else
        "멤버십 결제"
      end
    end

    def get_error_message(error_code)
      case error_code
      when "INVALID_CARD_NUMBER"
        "카드 번호가 올바르지 않습니다."
      when "INVALID_CARD_EXPIRY"
        "카드 유효기간이 올바르지 않습니다."
      when "INSUFFICIENT_BALANCE"
        "잔액이 부족합니다."
      when "EXCEED_MAX_AMOUNT"
        "결제 금액이 한도를 초과했습니다."
      when "REJECTED_CARD"
        "거절된 카드입니다."
      else
        "결제 처리 중 오류가 발생했습니다."
      end
    end
  end
end

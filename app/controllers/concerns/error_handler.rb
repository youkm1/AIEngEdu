module ErrorHandler
  extend ActiveSupport::Concern
  
  included do
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_invalid_record
    rescue_from StandardError, with: :handle_standard_error
  end
  
  private
  
  def handle_not_found(exception)
    render json: error_json(
      message: "요청한 리소스를 찾을 수 없습니다"
    ), status: :not_found
  end
  
  def handle_invalid_record(exception)
    render json: error_json(
      message: "데이터 유효성 검증에 실패했습니다",
      errors: exception.record.errors.full_messages
    ), status: :unprocessable_entity
  end
  
  def handle_standard_error(exception)
    Rails.logger.error "#{exception.class}: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    render json: error_json(
      message: "처리 중 오류가 발생했습니다",
      errors: [exception.message]
    ), status: :internal_server_error
  end
  
  def handle_payment_error(message:, error_details: nil)
    render json: error_json(
      message: message,
      errors: error_details
    ), status: :payment_required
  end
end
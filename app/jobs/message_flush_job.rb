class MessageFlushJob
  include Sidekiq::Job
  
  sidekiq_options queue: 'critical', retry: 3, backtrace: true
  
  def perform
    Rails.logger.info "MessageFlushJob started"
    
    result = MessageCacheService.flush_to_database
    
    if result[:errors].any?
      Rails.logger.error "MessageFlushJob completed with errors: #{result[:errors]}"
    else
      Rails.logger.info "MessageFlushJob completed successfully: #{result[:flushed_count]} messages"
    end
    
    result
  end
end
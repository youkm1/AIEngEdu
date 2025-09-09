class ChatController < ApplicationController
  include ActionController::Live
  skip_before_action :verify_authenticity_token
  
  def create
    unless current_user
      return render json: { error: "User not found" }, status: :unprocessable_entity
    end
    
    @conversation = current_user.conversations.create!(title: params[:title])
    render json: @conversation
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def message
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'
    
    gemini = GeminiService.new
    message = params[:message]
    conversation_id = params[:conversation_id]
    audio_file = params[:audio_file]
    
    # 사용자 메시지 Redis 캐싱 (비동기) + 오디오 메타데이터
    user_message_id = MessageCacheService.cache_message(
      conversation_id,
      'user',
      message,
      audio_metadata: extract_audio_metadata(audio_file)
    )
    
    # 대화 히스토리 가져오기 (캐시 + DB 병합)
    conversation_history = MessageCacheService.get_message_history(
      conversation_id, 
      limit: 20
    ).map { |m| { role: m[:role], content: m[:content] } }
    
    # AI 응답 스트리밍
    ai_response = ""
    
    gemini.stream_chat(message, conversation_history) do |chunk|
      if chunk && !chunk.empty?
        ai_response += chunk
        
        # 실시간 SSE 전송
        response.stream.write "data: #{chunk.to_json}\n\n"
        
        # Redis Pub/Sub로 다른 클라이언트에게도 브로드캐스트
        MessageCacheService.publish_message(conversation_id, {
          type: 'chunk',
          content: chunk,
          message_id: user_message_id
        })
      end
    end
    
    # AI 응답 Redis 캐싱 (비동기)
    ai_message_id = MessageCacheService.cache_message(
      conversation_id,
      'assistant',
      ai_response
    )
    
    # 스트리밍 완료 신호
    response.stream.write "data: [DONE]\n\n"
    
    # 완료 브로드캐스트
    MessageCacheService.publish_message(conversation_id, {
      type: 'complete',
      user_message_id: user_message_id,
      ai_message_id: ai_message_id
    })
    
  rescue => e
    Rails.logger.error "SSE Error: #{e.message}"
    response.stream.write "data: {\"error\": \"#{e.message}\"}\n\n"
  ensure
    response.stream.close
  end
  
  # 대화 히스토리 조회 (캐시 우선)
  def history
    conversation_id = params[:id]
    limit = params[:limit]&.to_i || 50
    
    messages = MessageCacheService.get_message_history(conversation_id, limit: limit)
    
    render json: {
      conversation_id: conversation_id,
      messages: messages,
      total_count: messages.size,
      from_cache: true
    }
  end
  
  # 캐시 상태 확인 (관리자용)
  def cache_status
    stats = MessageCacheService.cache_stats
    render json: stats
  end
  
  # 수동 플러시 트리거 (관리자용)
  def flush_cache
    MessageFlushJob.perform_async
    render json: { message: "Flush job enqueued" }
  end

  private

  def current_user
    # 테스트용 간단한 인증
    @current_user ||= User.find_by(id: params[:user_id] || session[:user_id])
  end
  
  def extract_audio_metadata(audio_file)
    return nil unless audio_file.present?
    
    {
      has_audio: true,
      format: audio_file.content_type&.split('/')&.last || 'unknown',
      size: audio_file.size,
      filename: audio_file.original_filename
    }
  rescue => e
    Rails.logger.error "Audio metadata extraction failed: #{e.message}"
    nil
  end
end
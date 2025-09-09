class MessageCacheService
  CACHE_TTL = 1.hour
  FLUSH_BATCH_SIZE = 1000
  
  class << self
    # 메시지를 Redis에 캐싱
    def cache_message(conversation_id, role, content, timestamp = Time.current, audio_metadata: nil)
      message_data = {
        conversation_id: conversation_id,
        role: role,
        content: content,
        timestamp: timestamp.to_f,
        id: SecureRandom.uuid,
        audio_metadata: audio_metadata
      }
      
      # Conversation별 메시지 리스트에 추가
      $redis.lpush("conversation:#{conversation_id}:messages", message_data.to_json)
      $redis.expire("conversation:#{conversation_id}:messages", CACHE_TTL)
      
      # 전역 pending 메시지 목록에 추가 (플러시용)
      $redis.lpush("pending_messages", message_data.to_json)
      
      # 즉시 플러시가 필요한 경우를 위한 카운터
      pending_count = $redis.llen("pending_messages")
      
      # 임계치 도달 시 즉시 플러시 트리거
      if pending_count >= FLUSH_BATCH_SIZE
        MessageFlushJob.perform_async
      end
      
      message_data[:id]
    end
    
    # 대화의 캐시된 메시지 조회
    def get_cached_messages(conversation_id, limit: 50)
      messages_json = $redis.lrange("conversation:#{conversation_id}:messages", 0, limit - 1)
      
      messages_json.map do |json|
        data = JSON.parse(json, symbolize_names: true)
        data[:timestamp] = Time.at(data[:timestamp])
        data
      end.reverse # 시간순 정렬
    end
    
    # 실시간 메시지 스트리밍을 위한 채널 발행
    def publish_message(conversation_id, message_data)
      $redis.publish("conversation:#{conversation_id}", message_data.to_json)
    end
    
    # 캐시된 메시지를 DB로 플러시
    def flush_to_database
      start_time = Time.current
      flushed_count = 0
      errors = []
      
      Rails.logger.info "Starting message flush to database..."
      
      loop do
        # 배치 단위로 메시지 가져오기
        messages_json = $redis.multi do |redis|
          redis.lrange("pending_messages", -FLUSH_BATCH_SIZE, -1)
          redis.ltrim("pending_messages", 0, -FLUSH_BATCH_SIZE - 1)
        end.first
        
        break if messages_json.empty?
        
        # 메시지 파싱 및 그룹핑
        grouped_messages = messages_json.group_by do |json|
          JSON.parse(json)["conversation_id"]
        end
        
        # DB 트랜잭션으로 배치 삽입
        ActiveRecord::Base.transaction do
          grouped_messages.each do |conversation_id, msg_batch|
            messages_to_insert = msg_batch.map do |json|
              data = JSON.parse(json)
              {
                conversation_id: conversation_id,
                role: data["role"],
                content: data["content"],
                created_at: Time.at(data["timestamp"]),
                updated_at: Time.at(data["timestamp"])
              }
            end
            
            # 벌크 인서트
            Message.insert_all(messages_to_insert)
            flushed_count += messages_to_insert.size
          end
        end
      rescue => e
        errors << e.message
        Rails.logger.error "Flush error: #{e.message}"
      end
      
      duration = (Time.current - start_time).round(2)
      
      Rails.logger.info "Message flush completed: #{flushed_count} messages in #{duration}s"
      Rails.logger.error "Flush errors: #{errors.join(', ')}" if errors.any?
      
      {
        flushed_count: flushed_count,
        duration: duration,
        errors: errors
      }
    end
    
    # 대화 삭제 시 캐시 정리
    def clear_conversation_cache(conversation_id)
      $redis.del("conversation:#{conversation_id}:messages")
    end
    
    # Redis 메모리 상태 확인
    def cache_stats
      info = $redis.info("memory")
      pending_count = $redis.llen("pending_messages")
      
      {
        used_memory_mb: (info["used_memory"].to_i / 1024.0 / 1024.0).round(2),
        pending_messages: pending_count,
        redis_info: info
      }
    end
    
    # 메시지 히스토리 병합 (캐시 + DB)
    def get_message_history(conversation_id, limit: 50)
      # 캐시된 메시지
      cached = get_cached_messages(conversation_id, limit: limit)
      
      # DB에서 최신 메시지 (캐시에 없는 것들)
      last_cached_time = cached.last&.dig(:timestamp) || 1.hour.ago
      
      db_messages = Message.where(conversation_id: conversation_id)
                          .where("created_at < ?", last_cached_time)
                          .order(created_at: :desc)
                          .limit(limit - cached.size)
                          .map do |msg|
        {
          id: msg.id,
          conversation_id: msg.conversation_id,
          role: msg.role,
          content: msg.content,
          timestamp: msg.created_at
        }
      end
      
      # 병합 및 정렬
      all_messages = (cached + db_messages).sort_by { |m| m[:timestamp] }
      all_messages.last(limit)
    end
  end
end
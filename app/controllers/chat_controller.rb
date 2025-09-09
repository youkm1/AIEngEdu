class ChatController < ApplicationController
  include ActionController::Live
  
  def create
    @conversation = current_user.conversations.create!(title: params[:title])
    render json: @conversation
  end

  def message
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'
    
    gemini = GeminiService.new
    message = params[:message]
    conversation_id = params[:conversation_id]
    
    # 메시지 저장
    user_message = Message.create!(
      conversation_id: conversation_id,
      role: 'user',
      content: message
    )
    
    # AI 응답 스트리밍
    ai_response = ""
    
    gemini.stream_chat(message) do |chunk|
      ai_response += chunk if chunk
      response.stream.write "data: #{chunk.to_json}\n\n"
    end
    
    # AI 응답 저장
    Message.create!(
      conversation_id: conversation_id,
      role: 'assistant',
      content: ai_response
    )
    
    response.stream.write "data: [DONE]\n\n"
  rescue => e
    Rails.logger.error "SSE Error: #{e.message}"
    response.stream.write "data: {\"error\": \"#{e.message}\"}\n\n"
  ensure
    response.stream.close
  end

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
end
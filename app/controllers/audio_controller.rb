class AudioController < ApplicationController
  before_action :set_message, only: [:show]
  
  # GET /audio/:message_id
  def show
    unless @message.has_audio?
      render json: { error: "No audio available for this message" }, status: :not_found
      return
    end
    
    # 오디오 파일 스트리밍 반환
    send_data @message.user_audio.download,
              type: @message.user_audio.content_type,
              disposition: 'inline',
              filename: "message_#{@message.id}_audio.#{@message.audio_format}"
  rescue => e
    Rails.logger.error "Audio streaming error: #{e.message}"
    render json: { error: "Failed to stream audio" }, status: :internal_server_error
  end
  
  # POST /audio/upload
  def upload
    audio_file = params[:audio_file]
    message_id = params[:message_id]
    
    unless audio_file.present?
      render json: { error: "No audio file provided" }, status: :bad_request
      return
    end
    
    unless valid_audio_format?(audio_file.content_type)
      render json: { error: "Unsupported audio format" }, status: :bad_request
      return
    end
    
    if audio_file.size > 10.megabytes
      render json: { error: "Audio file too large (max 10MB)" }, status: :bad_request
      return
    end
    
    # 메시지 찾기 및 오디오 첨부
    message = Message.find_by(id: message_id)
    unless message
      render json: { error: "Message not found" }, status: :not_found
      return
    end
    
    # 오디오 파일 첨부 및 메타데이터 업데이트
    message.user_audio.attach(audio_file)
    message.update!(
      has_user_audio: true,
      audio_format: extract_format_from_content_type(audio_file.content_type),
      audio_duration: extract_duration(audio_file) # 구현 필요 시
    )
    
    render json: { 
      message: "Audio uploaded successfully",
      audio_url: message.audio_url,
      message_id: message.id
    }
    
  rescue => e
    Rails.logger.error "Audio upload error: #{e.message}"
    render json: { error: "Failed to upload audio" }, status: :internal_server_error
  end
  
  private
  
  def set_message
    @message = Message.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Message not found" }, status: :not_found
  end
  
  def valid_audio_format?(content_type)
    allowed_types = %w[
      audio/wav audio/wave audio/x-wav
      audio/mp3 audio/mpeg
      audio/mp4 audio/m4a
      audio/webm audio/ogg
    ]
    allowed_types.include?(content_type)
  end
  
  def extract_format_from_content_type(content_type)
    case content_type
    when /wav/
      'wav'
    when /mp3|mpeg/
      'mp3'
    when /mp4|m4a/
      'm4a'
    when /webm/
      'webm'
    when /ogg/
      'ogg'
    else
      'unknown'
    end
  end
  
  def extract_duration(audio_file)
    # 실제 구현 시 FFmpeg 또는 다른 라이브러리 사용
    # 현재는 간단히 파일 크기 기반 추정
    estimated_duration = audio_file.size.to_f / (128 * 1024 / 8) # 128kbps 기준
    [estimated_duration, 300.0].min # 최대 5분
  rescue
    nil
  end
end
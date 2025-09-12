require "httparty"
require "json"

class GeminiService
  include HTTParty
  base_uri "https://generativelanguage.googleapis.com/v1beta"

  def initialize
    @api_key = ENV["GEMINI_API_KEY"]
    @model = "gemini-2.0-flash-exp"
  end

  def chat(message, conversation_history = [])
    response = self.class.post(
      "/models/#{@model}:generateContent",
      headers: {
        "Content-Type" => "application/json",
        "X-goog-api-key" => @api_key
      },
      body: build_request_body(message, conversation_history).to_json
    )

    if response.success?
      extract_text_from_response(response)
    else
      Rails.logger.error "Gemini API Error: #{response.code} - #{response.body}"
      "Sorry, a temporary error occurred."
    end
  rescue => e
    Rails.logger.error "Gemini Service Error: #{e.message}"
    "Sorry, a service error occurred."
  end

  # Transcribe audio using Gemini's multimodal capabilities
  def transcribe_audio(audio_file)
    # Convert audio file to base64
    audio_data = Base64.strict_encode64(audio_file.read)
    
    response = self.class.post(
      "/models/#{@model}:generateContent",
      headers: {
        "Content-Type" => "application/json",
        "X-goog-api-key" => @api_key
      },
      body: {
        contents: [
          {
            role: "user",
            parts: [
              {
                inline_data: {
                  mime_type: audio_file.content_type || "audio/webm",
                  data: audio_data
                }
              },
              {
                text: "Please transcribe this audio to text. Return only the transcribed text without any additional formatting or explanation."
              }
            ]
          }
        ],
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 1024,
          topP: 1,
          topK: 1
        }
      }.to_json
    )

    if response.success?
      extract_text_from_response(response).strip
    else
      Rails.logger.error "Gemini Audio Transcription Error: #{response.code} - #{response.body}"
      "Unable to convert audio to text."
    end
  rescue => e
    Rails.logger.error "Audio Transcription Error: #{e.message}"
    "An error occurred during audio transcription."
  end

  def stream_chat(message, conversation_history = [])
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{@model}:streamGenerateContent?alt=sse")

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["X-goog-api-key"] = @api_key
      request.body = build_request_body(message, conversation_history).to_json

      http.request(request) do |response|
        response.read_body do |chunk|
          if chunk.start_with?("data: ")
            json_str = chunk[6..-1].strip
            next if json_str == "[DONE]"

            begin
              data = JSON.parse(json_str)
              text = extract_text_from_streaming_response(data)
              yield text if text && block_given?
            rescue JSON::ParserError => e
              Rails.logger.error "JSON Parse Error: #{e.message}"
            end
          end
        end
      end
    end
  rescue => e
    Rails.logger.error "Streaming Error: #{e.message}"
    yield "Error: #{e.message}" if block_given?
  end

  private

  def build_request_body(message, conversation_history = [])
    contents = []
    
    # Add system instruction to always respond in English
    contents << {
      role: "user",
      parts: [ { text: "IMPORTANT: You must ALWAYS respond in English only. Never respond in any other language, regardless of the input language." } ]
    }
    contents << {
      role: "model",
      parts: [ { text: "I understand. I will always respond in English only." } ]
    }
    
    # Add conversation history
    contents += conversation_history.map do |msg|
      {
        role: msg[:role] == "assistant" ? "model" : "user",
        parts: [ { text: msg[:content] } ]
      }
    end

    contents << {
      role: "user",
      parts: [ { text: message } ]
    }

    {
      contents: contents,
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 2048,
        topP: 0.95,
        topK: 40
      }
    }
  end

  def extract_text_from_response(response)
    response.dig("candidates", 0, "content", "parts", 0, "text") ||
      "Unable to generate a response."
  end

  def extract_text_from_streaming_response(data)
    data.dig("candidates", 0, "content", "parts", 0, "text")
  end
end

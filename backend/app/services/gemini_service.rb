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
      "죄송합니다. 일시적인 오류가 발생했습니다."
    end
  rescue => e
    Rails.logger.error "Gemini Service Error: #{e.message}"
    "죄송합니다. 서비스 오류가 발생했습니다."
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
    contents = conversation_history.map do |msg|
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
      "응답을 생성할 수 없습니다."
  end

  def extract_text_from_streaming_response(data)
    data.dig("candidates", 0, "content", "parts", 0, "text")
  end
end

require "test_helper"

class ChatControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @conversation = create(:conversation, user: @user)
  end

  test "should create conversation" do
    assert_difference("Conversation.count", 1) do
      post chat_url, params: {
        title: "New Chat",
        user_id: @user.id
      }
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "New Chat", json_response["title"]
  end

  test "should send message to conversation" do
    # Gemini 서비스 모킹
    mock_service = Minitest::Mock.new
    mock_service.expect(:stream_chat, nil) do |message, &block|
      block.call("Test AI response") if block
    end

    GeminiService.stub(:new, mock_service) do
      # Messages are cached in Redis, not saved to DB immediately
      post chat_message_url, params: {
        conversation_id: @conversation.id,
        message: "Hello, AI!",
        user_id: @user.id
      }

      assert_response :success
      assert_equal "text/event-stream", response.headers["Content-Type"]
    end
  end

  test "should handle empty message" do
    post chat_message_url, params: {
      conversation_id: @conversation.id,
      message: "",
      user_id: @user.id
    }

    assert_response :success
  end

  test "should handle invalid conversation_id" do
    post chat_message_url, params: {
      conversation_id: 999999,
      message: "Test message",
      user_id: @user.id
    }

    assert_response :success
  end

  test "should stream response with SSE format" do
    # Mock Gemini response
    mock_service = Minitest::Mock.new
    mock_service.expect(:stream_chat, nil) do |message, &block|
      block.call("Chunk 1") if block
      block.call("Chunk 2") if block
    end

    GeminiService.stub(:new, mock_service) do
      post chat_message_url, params: {
        conversation_id: @conversation.id,
        message: "Test streaming",
        user_id: @user.id
      }

      assert_response :success

      # SSE 포맷 확인
      response_body = response.body
      assert_match /data: /, response_body
      assert_match /\[DONE\]/, response_body
    end
  end

  test "should return error without user" do
    post chat_url, params: {
      title: "New Chat"
    }

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response["error"].present?
  end
end

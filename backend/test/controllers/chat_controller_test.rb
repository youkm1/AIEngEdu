require "test_helper"

class ChatControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @conversation = create(:conversation, user: @user)
    # 테스트용 쿠폰 생성
    @coupon = create(:coupon, 
      user: @user, 
      name: "Test Coupon",
      total_uses: 5,
      used_count: 0,
      expires_at: 1.month.from_now
    )
  end

  test "should create conversation with active membership without using coupon" do
    # 활성 멤버십 생성
    create(:membership, user: @user, status: 'active', end_date: 1.month.from_now)
    
    assert_difference("Conversation.count", 1) do
      # 쿠폰은 사용되지 않아야 함
      assert_no_difference("@coupon.reload.used_count") do
        post chat_url, params: {
          title: "New Chat",
          user_id: @user.id
        }
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "New Chat", json_response["title"]
    assert_equal "membership", json_response["access_method"]
    assert json_response["membership_info"].present?
    assert_nil json_response["used_coupon"]
  end

  test "should create conversation with coupon when no membership" do
    # 멤버십 없이 쿠폰만 있는 상태
    assert_difference("Conversation.count", 1) do
      assert_difference("@coupon.reload.used_count", 1) do
        post chat_url, params: {
          title: "New Chat",
          user_id: @user.id
        }
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "New Chat", json_response["title"]
    assert_equal "coupon", json_response["access_method"]
    assert json_response["used_coupon"].present?
    assert_equal 4, json_response["used_coupon"]["remaining_uses"]
  end

  test "should not create conversation without membership or coupon" do
    # 쿠폰을 모두 사용하거나 만료시킴
    @coupon.update!(used_count: @coupon.total_uses)
    
    assert_no_difference("Conversation.count") do
      post chat_url, params: {
        title: "New Chat",
        user_id: @user.id
      }
    end

    assert_response :forbidden
    json_response = JSON.parse(response.body)
    assert json_response["error"].present?
    assert_match /멤버십.*쿠폰/, json_response["error"]
    assert_equal false, json_response["has_membership"]
    assert_equal false, json_response["has_coupons"]
  end

  test "should not create conversation with expired coupon and no membership" do
    # 쿠폰 만료
    @coupon.update!(expires_at: 1.day.ago)
    
    assert_no_difference("Conversation.count") do
      post chat_url, params: {
        title: "New Chat",
        user_id: @user.id
      }
    end

    assert_response :forbidden
    json_response = JSON.parse(response.body)
    assert json_response["error"].present?
  end

  test "should use coupon when membership is expired" do
    # 만료된 멤버십 생성
    create(:membership, 
      user: @user, 
      status: 'expired', 
      start_date: 2.months.ago,
      end_date: 1.day.ago
    )
    
    assert_difference("Conversation.count", 1) do
      # 멤버십이 만료되었으므로 쿠폰 사용
      assert_difference("@coupon.reload.used_count", 1) do
        post chat_url, params: {
          title: "New Chat",
          user_id: @user.id
        }
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "coupon", json_response["access_method"]
    assert json_response["used_coupon"].present?
  end

  test "should send message to conversation" do
    # Gemini 서비스 모킹
    mock_service = Minitest::Mock.new
    mock_service.expect(:stream_chat, nil) do |message, &block|
      block.call("Test AI response") if block
    end

    GeminiService.stub(:new, mock_service) do
      # Messages should be cached in Redis (not saved to DB immediately)
      post chat_message_url, params: {
        conversation_id: @conversation.id,
        message: "Hello, AI!",
        user_id: @user.id
      }

      assert_response :success
      assert_equal "text/event-stream", response.headers["Content-Type"]

      # Verify messages were cached in Redis
      cached_messages = MessageCacheService.get_cached_messages(@conversation.id)
      assert_equal 2, cached_messages.size
      assert_equal "user", cached_messages[0][:role]
      assert_equal "Hello, AI!", cached_messages[0][:content]
      assert_equal "assistant", cached_messages[1][:role]
      assert_equal "Test AI response", cached_messages[1][:content]
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

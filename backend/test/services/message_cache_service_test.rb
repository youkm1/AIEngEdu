require "test_helper"

class MessageCacheServiceTest < ActiveSupport::TestCase
  setup do
    # Clear Redis before each test to start fresh
    $redis.flushdb
  end

  test "should cache message" do
    # Given
    conversation_id = "test-conversation-123"
    role = "user"
    content = "Hello, world!"

    # When
    message_id = MessageCacheService.cache_message(conversation_id, role, content)

    # Then
    assert_not_nil message_id
    assert_match(/^[a-f0-9\-]+$/, message_id) # UUID 형식
  end

  test "should get cached messages" do
    # Given
    conversation_id = "test-conversation-456"
    MessageCacheService.cache_message(conversation_id, "user", "Message 1")
    MessageCacheService.cache_message(conversation_id, "assistant", "Message 2")

    # When
    messages = MessageCacheService.get_cached_messages(conversation_id)

    # Then
    assert_equal 2, messages.size
    assert_equal "user", messages[ 0 ][:role]
    assert_equal "Message 1", messages[ 0 ][:content]
    assert_equal "assistant", messages[ 1 ][:role]
    assert_equal "Message 2", messages[ 1 ][:content]
  end

  test "should clear conversation cache" do
    # Given
    conversation_id = "test-conversation-789"
    MessageCacheService.cache_message(conversation_id, "user", "Test message")

    # When
    MessageCacheService.clear_conversation_cache(conversation_id)
    messages = MessageCacheService.get_cached_messages(conversation_id)

    # Then
    assert_empty messages
  end

  test "should get cache stats" do
    # When
    stats = MessageCacheService.cache_stats

    # Then
    assert_not_nil stats[:used_memory_mb]
    assert_not_nil stats[:pending_messages]
    assert_not_nil stats[:redis_info]
  end
end
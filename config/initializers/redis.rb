require 'redis'

# Redis 연결 설정
$redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))

# Rails 캐시 스토어로 Redis 설정
Rails.application.config.cache_store = :redis_cache_store, {
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
}
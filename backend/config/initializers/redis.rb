require "redis"

# 환경별 Redis 호스트 설정
redis_host = ENV["DOCKER_ENV"] ? "redis" : "localhost"

# MessageCacheService용 Redis (DB 0)
$redis = Redis.new(url: "redis://#{redis_host}:6379/0")

# Rails 캐시 스토어 (테스트 환경 제외)
unless Rails.env.test?
  Rails.application.config.cache_store = :redis_cache_store, {
    url: "redis://#{redis_host}:6379/0"
  }
end

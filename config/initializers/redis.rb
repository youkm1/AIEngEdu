require "redis"

# 환경별 Redis 호스트 설정
redis_host = ENV["DOCKER_ENV"] ? "redis" : "localhost"

# MessageCacheService용 Redis (DB 0)
$redis = Redis.new(url: "ringle_redis://#{redis_host}:6379/0")

# Rails 캐시 스토어도 동일한 DB 사용
Rails.application.config.cache_store = :redis_cache_store, {
  url: "ringle_redis://#{redis_host}:6379/0"
}

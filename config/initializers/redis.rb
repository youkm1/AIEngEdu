require "redis"

# Redis 연결 설정 (환경별 호스트 설정)
redis_host = ENV["DOCKER_ENV"] ? "redis" : "localhost"
redis_url = ENV.fetch("REDIS_URL", "redis://#{redis_host}:6379/0")

$redis = Redis.new(url: redis_url)

# Rails 캐시 스토어로 Redis 설정
Rails.application.config.cache_store = :redis_cache_store, {
  url: redis_url
}

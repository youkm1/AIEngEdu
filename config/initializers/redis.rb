require "redis"

# 테스트 환경에서는 Redis 초기화 건너뛰기
unless Rails.env.test?
  # 환경별 Redis 호스트 설정
  redis_host = ENV["DOCKER_ENV"] ? "redis" : "localhost"

  # MessageCacheService용 Redis (DB 0)
  $redis = Redis.new(url: "redis://#{redis_host}:6379/0")

  # Rails 캐시 스토어도 동일한 DB 사용 (개발환경만)
  Rails.application.config.cache_store = :redis_cache_store, {
    url: "redis://#{redis_host}:6379/0"
  }
else
  # 테스트 환경에서는 mock Redis 사용
  $redis = double("Redis", 
    lpush: true, 
    expire: true, 
    llen: 0, 
    lrange: [], 
    publish: true, 
    multi: [], 
    del: true, 
    info: {}, 
    ltrim: true
  )
end

require "sidekiq"
require "sidekiq-cron"

# 환경별 Redis 호스트 설정
redis_host = ENV["DOCKER_ENV"] ? "redis" : "localhost"

Sidekiq.configure_server do |config|
  config.redis = { url: "ringle_redis#{redis_host}:6379/1" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "ringle_redis://#{redis_host}:6379/1" }
end

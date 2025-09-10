require "sidekiq"
require "sidekiq-cron"

# 환경별 Redis URL 설정
redis_host = ENV["DOCKER_ENV"] ? "redis" : "localhost"
sidekiq_redis_url = ENV.fetch("SIDEKIQ_REDIS_URL", "redis://#{redis_host}:6379/1")

Sidekiq.configure_server do |config|
  config.redis = { url: sidekiq_redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: sidekiq_redis_url }
end

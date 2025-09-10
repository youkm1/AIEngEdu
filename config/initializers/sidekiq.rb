require "sidekiq"
require "sidekiq-cron"

# 테스트 환경이 아닐 때만 Sidekiq 설정
unless Rails.env.test?
  # 환경별 Redis 호스트 설정
  redis_host = ENV["DOCKER_ENV"] ? "redis" : "localhost"

  Sidekiq.configure_server do |config|
    config.redis = { url: "redis://#{redis_host}:6379/1" }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: "redis://#{redis_host}:6379/1" }
  end
end

require "sidekiq"
require "sidekiq-cron"

# 테스트 환경이 아닐 때만 Sidekiq 설정
unless Rails.env.test?
  # 환경별 Redis 호스트 설정
  redis_host = ENV["DOCKER_ENV"] ? "redis" : "localhost"

  Sidekiq.configure_server do |config|
    config.redis = { url: "redis://#{redis_host}:6379/1" }
    
    # Sidekiq 서버 시작 시 cron 작업 스케줄링
    config.on(:startup) do
      # 매시간 메시지 플러시 작업
      Sidekiq::Cron::Job.create({
        'name' => 'message_flush',
        'cron' => '0 * * * *', # 매시간 0분에 실행
        'class' => 'MessageFlushJob',
        'queue' => 'critical'
      })
      
      Rails.logger.info "Sidekiq cron jobs scheduled successfully"
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: "redis://#{redis_host}:6379/1" }
  end
end

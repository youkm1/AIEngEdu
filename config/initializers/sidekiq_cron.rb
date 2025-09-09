require 'sidekiq-cron'

Rails.application.config.after_initialize do
  # 매시간 정각에 메시지 플러시
  Sidekiq::Cron::Job.load_from_hash({
    'message_flush' => {
      'cron' => '0 * * * *',
      'class' => 'MessageFlushJob',
      'description' => 'Flush cached messages to database every hour'
    }
  })

  # 5분마다 캐시 상태 모니터링 (프로덕션만)
  if Rails.env.production?
    Sidekiq::Cron::Job.load_from_hash({
      'cache_monitor' => {
        'cron' => '*/5 * * * *',
        'class' => 'CacheMonitorJob',
        'description' => 'Monitor cache status every 5 minutes'
      }
    })
  end
end
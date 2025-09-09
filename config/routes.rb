Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    resources :users
  end

  # Chat routes
  post "chat", to: "chat#create"
  post "chat/message", to: "chat#message", as: :chat_message
  post "chat/simple", to: "chat#simple_message"  # 테스트용
  get "chat/:id/history", to: "chat#history", as: :chat_history
  get "chat/cache/status", to: "chat#cache_status"
  post "chat/cache/flush", to: "chat#flush_cache"
  
  # Audio routes
  get "audio/:id", to: "audio#show", as: :audio_message
  post "audio/upload", to: "audio#upload"

  # Root
  root "rails/health#show"
end

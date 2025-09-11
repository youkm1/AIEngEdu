Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    # Auth routes
    namespace :auth do
      post :login
      get :me
    end
    
    resources :users do
      resources :memberships, only: [ :index, :create ]
      resources :coupons do
        collection do
          get :available
        end
      end
    end

    resources :memberships, only: [ :show, :update, :destroy ] do
      collection do
        get :active
        post :batch_create
      end
    end

    # Admin routes
    namespace :admin do
      resources :memberships, only: [ :index, :destroy ] do
        collection do
          post :assign, as: :assign
        end
      end
    end

    # Payment routes (Mock Toss Payments)
    resources :payments, only: [ :show ], param: :payment_key do
      collection do
        post :prepare, as: :prepare
        post :confirm, as: :confirm
        post :cancel
        post :webhook
        get :success
        get :fail
        post :simulate_failure
      end
    end
  end

  # Chat routes
  post "chat", to: "chat#create"
  post "chat/message", to: "chat#message", as: :chat_message
  post "chat/message/audio", to: "chat#message_audio", as: :chat_message_audio
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

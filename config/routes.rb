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

  # Root
  root "rails/health#show"
end

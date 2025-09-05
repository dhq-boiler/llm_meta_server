Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    sessions: "users/sessions"
  }

  # 独自のセッションルート（すべてDevise scope内で定義）
  devise_scope :user do
    delete "/logout", to: "users/sessions#destroy", as: :user_logout
    get "/logout", to: "users/sessions#destroy"
    get "/users/sessions/sso_logout", to: "users/sessions#sso_logout", as: :sso_logout_users_sessions
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # User profile routes
  get "/profile", to: "user#show", as: :user_profile

  # Defines the root path route ("/")
  root "home#index"
end

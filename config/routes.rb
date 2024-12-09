require 'sidekiq/web'

Rails.application.routes.draw do
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
    mount ExceptionTrack::Engine => '/exception-track'
  end

  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "products#index"

  resources :products, only: [ :index ]
  resources :carts, only: [ :index, :show ]
  resources :cart_items, only: [ :create, :update, :destroy ]
  resources :orders, only: [ :index, :create, :update ]

  post "/auth/telegram", to: "auth#telegram_auth"

  namespace :admin do
    get "/dashboard", to: "dashboard#index"
    get "/", to: "dashboard#index"
    resources :products
  end
end

require 'sidekiq_unique_jobs/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/admin/sidekiq'
    mount Blazer::Engine, at: '/admin/blazer'
    mount PgHero::Engine, at: '/admin/pghero'
    mount ActiveStorageDashboard::Engine, at: '/admin/active-storage-dashboard'
  end

  devise_for :users, controllers: { registrations: 'users/registrations' }

  root 'products#index'

  resources :products, only: %i[index show] do
    resources :reviews, only: %i[index new create]
    resource :product_subscription, only: %i[create destroy]
    resource :favorites, only: %i[create destroy]
  end
  resources :product_subscriptions, only: :index
  resources :favorites, only: %i[index]
  resources :carts, only: %i[index destroy]
  resources :cart_items, only: %i[create update]
  resources :orders, only: %i[index show create update]
  resources :support, only: :index
  resources :surveys, only: :index
  post :add_answers, to: 'surveys#add_answers'

  post '/auth/telegram', to: 'auth#telegram'
  get '/login', to: 'auth#login'
  get '/error-register', to: 'auth#error_register'
  get '/user-checker', to: 'auth#user_checker'

  post 'webhook/update-product-stock', to: 'webhook#update_product_stock'
  get '/proxy/clean_email', to: 'proxy#clean_email'

  devise_scope :user do
    get '/edit_email', to: 'devise/registrations#edit_email', as: :edit_email
    patch '/change_email', to: 'users/registrations#change_email', as: :change_email
  end

  get 'service-worker' => 'pwa#service_worker', as: :pwa_service_worker
  get 'manifest.json' => 'pwa#manifest', as: :pwa_manifest
  get '/offline.html' => 'pwa#offline'

  draw :admin
  draw :api_v1

  match '*unmatched', to: 'application#redirect_to_telegram', via: :all,
                      constraints: ->(req) { !req.path.start_with?('/rails/active_storage') }
end

require 'sidekiq/web'

Rails.application.routes.draw do
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  devise_for :users, controllers: { registrations: 'users/registrations' }

  root 'auth#login'

  resources :products, only: %i[index show] do
    resources :reviews, only: %i[new create edit update]
    resource :product_subscription, only: %i[create destroy]
  end
  resources :carts, only: [:index]
  resources :cart_items, only: %i[create update]
  resources :orders, only: %i[index create update]

  post '/auth/media_sender_service.rb', to: 'auth#telegram_auth'
  get '/login', to: 'auth#login'
  get '/error-register', to: 'auth#error_register'
  get '/user-checker', to: 'auth#user_checker'

  post 'webhook/update-product-stock', to: 'webhook#update_product_stock'

  draw :admin

  match '*unmatched', to: 'application#redirect_to_telegram', via: :all,
                      constraints: ->(req) { !req.path.start_with?('/rails/active_storage') }
end

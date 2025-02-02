require 'sidekiq/web'

Rails.application.routes.draw do
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
    # mount ExceptionTrack::Engine => '/exception-track'
  end

  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  root 'auth#login'

  resources :products, only: [:index, :show] do
    resources :reviews, only: [:new, :create, :edit, :update]
  end
  resources :carts, only: [:index]
  resources :cart_items, only: [:create, :update]
  resources :orders, only: [:index, :create, :update]

  post '/auth/telegram', to: 'auth#telegram_auth'
  get '/login', to: 'auth#login'

  namespace :admin do
    get '/login', to: 'dashboard#login'
    get '/dashboard', to: 'dashboard#index'
    get '/', to: 'dashboard#index'
    resources :products
    resources :settings
    resources :orders
    resources :users
    resources :mailings
    resources :analytics, only: :index
    resources :messages, only: [:index, :new, :create, :destroy]
    resources :reviews
  end

  match '*unmatched', to: 'application#redirect_to_telegram', via: :all,
        constraints: lambda { |req| !req.path.start_with?('/rails/active_storage') }
end

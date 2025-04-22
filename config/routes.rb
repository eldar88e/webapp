require 'sidekiq/web'

Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/admin/sidekiq'
    mount Blazer::Engine, at: '/admin/blazer'
  end

  devise_for :users, controllers: { registrations: 'users/registrations' }

  root 'products#index'

  resources :products, only: %i[index show] do
    resources :reviews, only: %i[new create edit update]
    resource :product_subscription, only: %i[create destroy]
  end
  resources :carts, only: [:index]
  resources :cart_items, only: %i[create update]
  resources :orders, only: %i[index create update]
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

  draw :admin

  match '*unmatched', to: 'application#redirect_to_telegram', via: :all,
                      constraints: ->(req) { !req.path.start_with?('/rails/active_storage') }
end

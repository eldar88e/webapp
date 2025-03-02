namespace :admin do
  get '/', to: 'dashboard#index'
  get '/dashboard/show', to: 'dashboard#show' # TODO: temp route
  resources :products
  resources :settings
  resources :orders
  resources :users
  resources :mailings
  resources :analytics, only: :index
  resources :messages, only: %i[index new create destroy]
  resources :reviews
  resources :product_subscriptions, only: [:index]
  resources :bank_cards, only: %i[index new create edit update]
end

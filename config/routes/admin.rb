namespace :admin do
  get '/', to: 'dashboard#index'
  resources :products
  resources :settings
  resources :orders
  resources :users
  resources :mailings
  resources :analytics, only: :index
  resources :messages, only: %i[index create destroy] # TODO: delete all messages
  resources :support_entries, only: %i[index new create edit update destroy] # == except: :show
  resources :reviews
  resources :product_subscriptions, only: %i[index destroy]
  resources :bank_cards, only: %i[index new create edit update]
  get '/bank_cards/statistics', to: 'bank_cards#statistics'
  resources :attachments, only: %i[destroy]
  resources :bonus_logs, only: :index
  resources :purchases
  resources :purchase_items, only: %i[create update]
  resources :product_statistics, only: :index do
    get :xlsx, on: :collection
  end
  resources :tasks, only: %i[index show new create edit update] do
    resources :comments, only: %i[create]
  end
  patch '/tasks/:id/move', to: 'tasks#move'
  resources :expenses, except: :show
  resources :errors, only: %i[index show]
  resources :questions, except: :show
  resources :answers, only: :index
end

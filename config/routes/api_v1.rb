namespace :api do
  namespace :v1 do
    resources :products, only: [:index]
    resources :orders, only: [:index]
  end
end

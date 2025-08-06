Rails.application.routes.draw do
  devise_for :users
  devise_for :companies
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resource :cart, only: :show do
    post 'add/:product_id', to: 'carts#add', as: :add_item
    delete 'remove/:product_id', to: 'carts#remove', as: :remove_item
  end

  resources :orders, only: [:index, :show, :new, :create]
  resources :products
  resources :companies, only: [:index, :show, :new, :create]
  resources :categories

  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"
end

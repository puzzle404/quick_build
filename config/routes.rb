Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get 'up' => 'rails/health#show', as: :rails_health_check

  resource :cart, only: :show do
    post 'add/:product_id', to: 'cart#add', as: :add_item
    delete 'remove/:product_id', to: 'cart#remove', as: :remove_item
  end

  resources :orders, only: [:index, :show, :new, :create]
  resources :products, only: :index
  root 'products#index'
  resources :categories

  get "up" => "rails/health#show", as: :rails_health_check
  root "products#index"
end

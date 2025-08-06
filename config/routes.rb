Rails.application.routes.draw do
  devise_for :users
  devise_for :companies
  resources :products
  resources :categories

  get "up" => "rails/health#show", as: :rails_health_check


  resources :products, only: :index

  # Defines the root path route ("/")
  root "products#index"
end

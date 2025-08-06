Rails.application.routes.draw do
  devise_for :users
  devise_for :companies
  resources :products
  resources :categories

  get "up" => "rails/health#show", as: :rails_health_check


  root "products#index"

end

Rails.application.routes.draw do
  devise_for :users

  # Carrito
  resource :cart, only: :show do
    post 'add/:product_id', to: 'carts#add', as: :add_item
    delete 'remove/:product_id', to: 'carts#remove', as: :remove_item
  end

  # Órdenes
  resources :orders, only: [:index, :show, :new, :create]

  # Empresas y productos
  resources :companies, only: [:show, :new, :create] do
    resources :products, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  end
  get 'all_products', to: 'products#all_products', as: :products
  resources :categories

  # Namespace para constructores
  namespace :constructors do
    root to: "projects#index"
    resources :projects do
      resources :project_memberships, only: [:create, :destroy, :new]
    end
  end

  # Health check y root
  get "up" => "rails/health#show", as: :rails_health_check

  root to: "dashboards#show"
end

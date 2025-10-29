

Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine => "/jobs"

  root to: "dashboards#show"

  resource :registration, only: %i[new create]
  resource :session, only: %i[new create destroy]

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
    root to: "dashboard#index"
    resources :projects do
      resources :project_memberships, only: [:create, :destroy, :new]
      resource :planning, only: [:show], module: :projects, controller: :planning
      resource :documents, only: [:show], module: :projects, controller: :documents
      resources :stages, only: [:create, :destroy], module: :projects
      resources :people, module: :projects do
        resources :attendances, only: [:create], module: :people
      end
      resources :material_lists, module: :projects do
        patch :toggle_publication, on: :member
        resources :material_items, only: [:create, :destroy], module: :material_lists
      end
    end
  end

  resources :configurations, only: [] do
    get "ios_v1", on: :collection
    get "android_v1", on: :collection
  end

  get "refresh_app" => "hotwire#refresh", as: :refresh_app

  # Health check y root
  get "up" => "rails/health#show", as: :rails_health_check
end



Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine => "/jobs"

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    namespace :dev do
      get "styleguide", to: "styleguide#show"
    end
  end

  # Home público
  root to: "home#index"

  # Páginas estáticas (marketing/legal)
  get "terminos", to: "pages#terms", as: :terminos
  get "privacidad", to: "pages#privacy", as: :privacidad
  get "precios", to: "pages#pricing", as: :precios

  resources :contacts, only: :create
  resource :registration, only: %i[new create edit]
  resource :session, only: %i[new create destroy]
  resources :passwords, param: :token, only: %i[new create edit update]
  resource :preferences, only: %i[update]

  # Carrito
  resource :cart, only: :show do
    post "add/:product_id", to: "carts#add", as: :add_item
    delete "remove/:product_id", to: "carts#remove", as: :remove_item
  end

  # Órdenes
  resources :orders, only: [ :index, :show, :new, :create ]

  # Empresas y productos
  resources :companies, only: [ :show, :new, :create ] do
    resources :products, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
  end
  get "all_products", to: "products#all_products", as: :products
  resources :categories

  # Namespace para constructores
  namespace :constructors do
    root to: "dashboard#index"
    get "dashboard/evolution_chart", to: "dashboard#evolution_chart", as: :evolution_chart
    # Reporte imprimible de la cartera (HTML + @media print). El CSV del
    # dashboard sigue siendo GET /constructors.csv.
    get "reporte", to: "dashboard#report", as: :report
    resources :people, only: [ :index, :show, :edit, :update ]
    get "biblioteca", to: "library#index", as: :library
    get "biblioteca/:id", to: "library#show", as: :library_document, constraints: { id: /\d+/ }
    get "search", to: "search#index"
    # Plantillas de etapas reutilizables. Aplicarlas vive en
    # projects/stages#apply_template (necesita la obra destino).
    resources :stage_templates, only: [ :index, :create, :destroy ]
    resources :projects do
      resources :project_memberships, only: [ :create, :destroy ]
      # /planning redirige a /stages (la vista de planificación ahora vive en stages#index).
      resource :planning, only: [ :show ], module: :projects, controller: :planning
      resources :documents, only: [ :index, :create, :destroy ], module: :projects, controller: :documents
      resources :images, only: [ :index, :create, :destroy ], module: :projects, controller: :images
      resources :expenses, only: [ :index, :new, :create, :destroy ], module: false, controller: "/constructors/expenses"
      resources :notes, only: [ :new, :create, :destroy ], module: false, controller: "/constructors/notes"
      resources :stages, module: :projects do
        collection do
          post :apply_template
        end

        member do
          post :duplicate
          patch :complete
        end

        resources :documents, only: [ :new, :create, :destroy ], module: :stages
        resources :images, only: [ :new, :create, :destroy ], module: :stages
        resources :expenses, only: [ :new, :create, :destroy ], module: false, controller: "/constructors/expenses"
        resources :notes, only: [ :new, :create, :destroy ], module: false, controller: "/constructors/notes"
      end
      resources :people, module: :projects do
        # create = "dar presente" (un click). update = cargar las horas
        # después, sobre la marca que ya existe. destroy = deshacer una marca
        # equivocada (dar presente es un click, así que equivocarse también).
        resources :attendances, only: [ :create, :update, :destroy ], module: :people
      end
      resources :material_lists, module: :projects do
        patch :toggle_publication, on: :member
        patch :mark_as_paid, on: :member
        resources :material_items, only: [ :create, :destroy ], module: :material_lists
      end
      resources :blueprints, only: [ :index, :new, :create, :show, :destroy ], module: :projects do
        patch :update_scale, on: :member
        patch :update_measurements, on: :member

        resources :ai_analyses, only: [ :index, :create, :show, :destroy ], module: :blueprints do
          post :apply, on: :member
        end
      end
    end
  end

  resources :configurations, only: [] do
    get "ios_v1", on: :collection
    get "android_v1", on: :collection
  end

  get "refresh_app" => "hotwire#refresh", as: :refresh_app

  # PWA — manifest + service worker (renderizados desde app/views/pwa/*)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest, defaults: { format: :json }
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker, defaults: { format: :js }

  # Health check y root
  get "up" => "rails/health#show", as: :rails_health_check
end

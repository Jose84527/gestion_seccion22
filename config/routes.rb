Rails.application.routes.draw do
  get "login", to: "sesiones#new", as: :login
  post "login", to: "sesiones#create"
  delete "logout", to: "sesiones#destroy", as: :logout

  get "menu", to: "home#menu", as: :menu

  get "finanzas", to: "finanzas/dashboard#index", as: :finanzas

  resources :historiales, only: %i[index show]

  resources :trabajadores, only: %i[index show new create edit update]

  resources :usuarios, only: %i[index new create edit update] do
    get :buscar_trabajadores, on: :collection
  end

  resources :concepto07_niveles, only: %i[index new create edit update] do
    patch :cambiar_estado, on: :member
  end

  resources :cooperaciones do
  collection do
    get :buscar_trabajadores
  end

  member do
    patch :cambiar_estado
    get :pdf_lista_general
    get :pdf_recibos
    get :confirmacion
    patch :confirmar
    get :ver_lista_confirmacion

    get :corregir_evidencia
    patch :actualizar_evidencia
  end
end

  get "home/index"

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
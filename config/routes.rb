Rails.application.routes.draw do
  get "login", to: "sesiones#new", as: :login
  post "login", to: "sesiones#create"
  delete "logout", to: "sesiones#destroy", as: :logout

  get "menu", to: "home#menu", as: :menu

  resources :historiales, only: %i[index show]

  resources :trabajadores, only: %i[index show new create edit update] do
    patch :cambiar_estado, on: :member
  end

  resources :usuarios, only: %i[index new create edit update] do
    get :buscar_trabajadores, on: :collection
  end

  resources :concepto07_niveles, only: %i[index new create edit update] do
    patch :cambiar_estado, on: :member
  end

  get "home/index"

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
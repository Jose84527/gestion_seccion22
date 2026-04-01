Rails.application.routes.draw do
  get "login", to: "sesiones#new", as: :login
  post "login", to: "sesiones#create"
  delete "logout", to: "sesiones#destroy", as: :logout

  get "menu", to: "home#menu", as: :menu

  resources :historiales, only: %i[index show]
  
  get "home/index"

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
  
end

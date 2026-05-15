Rails.application.routes.draw do
  get "login", to: "sesiones#new", as: :login
  post "login", to: "sesiones#create"
  delete "logout", to: "sesiones#destroy", as: :logout

  get "menu", to: "home#menu", as: :menu

  get "finanzas", to: "finanzas/dashboard#index", as: :finanzas
  get "finanzas/reportes", to: "finanzas/reportes#index", as: :finanzas_reportes
  get "finanzas/reportes/excel", to: "finanzas/reportes#excel", as: :finanzas_reportes_excel
  get "finanzas/reportes/pdf", to: "finanzas/reportes#pdf", as: :finanzas_reportes_pdf

  resources :historiales, only: %i[index show]

  resources :trabajadores, only: %i[index show new create edit update]

  resources :usuarios, only: %i[index new create edit update] do
    get :buscar_trabajadores, on: :collection
  end

  resources :concepto07_niveles, only: %i[index new create edit update] do
    patch :cambiar_estado, on: :member
  end

  resources :cuenta_financieras,
            path: "cuentas_financieras",
            controller: "cuentas_financieras",
            only: %i[index new create edit update] do
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

  resources :egresos do
    member do
      patch :cancelar
      get :pdf
      get :confirmacion
      patch :confirmar
      get :ver_evidencia
      get :corregir_evidencia
      patch :actualizar_evidencia
    end
  end

  get "eventos/dashboard", to: "eventos/dashboard#index", as: :eventos_dashboard

  get "eventos/dashboard/reporte_participacion_pdf",
      to: "eventos/dashboard#reporte_participacion_pdf",
      as: :eventos_reporte_participacion_pdf

  resources :eventos do
    collection do
      get :buscar_trabajadores
    end

    member do
      patch :cancelar
      get :confirmacion
      patch :confirmar
      get :ver_convocatoria
      get :ver_acta
      get :ver_lista_participacion
    end
  end

  get "home/index"

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
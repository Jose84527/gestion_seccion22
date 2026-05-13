module Eventos
  class DashboardController < ApplicationController
    before_action :autenticar_usuario
    before_action -> { requiere_permiso!(:eventos, :ver) }

    def index
      redirect_to eventos_path, notice: "El dashboard de eventos se integrará en la siguiente etapa."
    end
  end
end
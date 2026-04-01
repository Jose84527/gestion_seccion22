class HistorialesController < ApplicationController
  before_action :autenticar_usuario
  before_action -> { requiere_permiso!(:historial, :ver) }
  before_action :set_historial, only: :show

  def index
    @historiales = Historial.recientes
  end

  def show
  end

  private

  def set_historial
    @historial = Historial.find(params[:id])
  end
end
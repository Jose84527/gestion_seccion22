class HistorialesController < ApplicationController
  HISTORIALES_POR_PAGINA = 20

  before_action :autenticar_usuario
  before_action -> { requiere_permiso!(:historial, :ver) }
  before_action :set_historial, only: :show

  def index
    @fecha = params[:fecha].to_s

    base = Historial.recientes
    base = base.where(fecha_evento: rango_del_dia(@fecha)) if @fecha.present?

    @total_registros = base.count
    @total_paginas = (@total_registros.to_f / HISTORIALES_POR_PAGINA).ceil
    @total_paginas = 1 if @total_paginas.zero?

    @pagina_actual = params[:page].to_i
    @pagina_actual = 1 if @pagina_actual < 1
    @pagina_actual = @total_paginas if @pagina_actual > @total_paginas

    offset = (@pagina_actual - 1) * HISTORIALES_POR_PAGINA

    @historiales = base.offset(offset).limit(HISTORIALES_POR_PAGINA)
  end

  def show
  end

  private

  def set_historial
    @historial = Historial.find(params[:id])
  end

  def rango_del_dia(fecha_param)
    fecha = Date.parse(fecha_param)
    fecha.beginning_of_day..fecha.end_of_day
  rescue ArgumentError
    nil
  end
end
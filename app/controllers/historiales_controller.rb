class HistorialesController < ApplicationController
  HISTORIALES_POR_PAGINA = 20

  before_action :autenticar_usuario
  before_action -> { requiere_permiso!(:historial, :ver) }
  before_action :set_historial, only: :show

  def index
  @fecha = params[:fecha].to_s
  @modulo = params[:modulo].to_s

  @modulos_disponibles = Historial
                         .where.not(modulo: [nil, ""])
                         .distinct
                         .order(:modulo)
                         .pluck(:modulo)

  base = Historial
         .includes(:usuario)
         .order(created_at: :desc)

  if @fecha.present?
    fecha_parseada = Date.parse(@fecha)
    base = base.where(created_at: fecha_parseada.beginning_of_day..fecha_parseada.end_of_day)
  end

  if @modulo.present?
    base = base.where(modulo: @modulo)
  end

  @total_registros = base.count

  @pagina_actual = params[:page].to_i
  @pagina_actual = 1 if @pagina_actual < 1

  @por_pagina = 20
  @total_paginas = (@total_registros.to_f / @por_pagina).ceil
  @total_paginas = 1 if @total_paginas.zero?
  @pagina_actual = @total_paginas if @pagina_actual > @total_paginas

  offset = (@pagina_actual - 1) * @por_pagina

  @historiales = base.offset(offset).limit(@por_pagina)
rescue ArgumentError
  redirect_to historiales_path, alert: "La fecha seleccionada no es válida"
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
module Finanzas
  class ReportesController < ApplicationController
    before_action :autenticar_usuario
    before_action -> { requiere_permiso!(:cooperaciones, :ver) }

    def index
      @tipo = params[:tipo].presence_in(%w[general ingresos egresos]) || "general"

      @fecha_inicio = parsear_fecha(params[:fecha_inicio])
      @fecha_fin = parsear_fecha(params[:fecha_fin])

      @ingresos = ingresos_confirmados
      @egresos = egresos_confirmados

      @total_ingresos = @ingresos.sum { |cooperacion| cooperacion.total_esperado.to_d }
      @total_egresos = @egresos.sum { |egreso| egreso.monto.to_d }
      @saldo_final = @total_ingresos - @total_egresos
    end

    private

    def ingresos_confirmados
      base = Cooperacion.where(estado: "completada")

      if Cooperacion.column_names.include?("confirmada_at")
        base = aplicar_rango_datetime(base, :confirmada_at)
        base.order(confirmada_at: :desc)
      else
        base.order(created_at: :desc)
      end
    rescue StandardError
      Cooperacion.none
    end

    def egresos_confirmados
      base = Egreso.where(estado: "confirmado")
      base = aplicar_rango_date(base, :fecha_egreso)
      base.ordenados_por_folio
    rescue StandardError
      Egreso.none
    end

    def aplicar_rango_datetime(scope, columna)
      if @fecha_inicio.present?
        scope = scope.where("#{columna} >= ?", @fecha_inicio.beginning_of_day)
      end

      if @fecha_fin.present?
        scope = scope.where("#{columna} <= ?", @fecha_fin.end_of_day)
      end

      scope
    end

    def aplicar_rango_date(scope, columna)
      scope = scope.where("#{columna} >= ?", @fecha_inicio) if @fecha_inicio.present?
      scope = scope.where("#{columna} <= ?", @fecha_fin) if @fecha_fin.present?

      scope
    end

    def parsear_fecha(valor)
      return nil if valor.blank?

      Date.parse(valor.to_s)
    rescue ArgumentError
      nil
    end
  end
end
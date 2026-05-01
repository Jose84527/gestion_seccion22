module Finanzas
  class ReportesController < ApplicationController
    before_action :autenticar_usuario
    before_action -> { requiere_permiso!(:cooperaciones, :ver) }

    def index
      cargar_reporte
    end

    def excel
      cargar_reporte

      archivo = Excel::ReporteFinancieroXlsx.new(
        tipo: @tipo,
        fecha_inicio: @fecha_inicio,
        fecha_fin: @fecha_fin,
        ingresos: @ingresos,
        egresos: @egresos,
        total_ingresos: @total_ingresos,
        total_egresos: @total_egresos,
        saldo_final: @saldo_final
      ).render

      send_data archivo,
                filename: nombre_archivo_excel,
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                disposition: "attachment"
    end

    private

    def cargar_reporte
      @tipo = params[:tipo].presence_in(%w[general ingresos egresos]) || "general"

      @fecha_inicio = parsear_fecha(params[:fecha_inicio])
      @fecha_fin = parsear_fecha(params[:fecha_fin])

      @ingresos = ingresos_confirmados
      @egresos = egresos_confirmados

      @total_ingresos = @ingresos.sum { |cooperacion| cooperacion.total_esperado.to_d }
      @total_egresos = @egresos.sum { |egreso| egreso.monto.to_d }
      @saldo_final = @total_ingresos - @total_egresos
    end

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
      scope = scope.where("#{columna} >= ?", @fecha_inicio.beginning_of_day) if @fecha_inicio.present?
      scope = scope.where("#{columna} <= ?", @fecha_fin.end_of_day) if @fecha_fin.present?

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

    def nombre_archivo_excel
      fecha = Time.current.strftime("%Y%m%d_%H%M%S")
      "reporte_financiero_#{@tipo}_#{fecha}.xlsx"
    end
  end
end
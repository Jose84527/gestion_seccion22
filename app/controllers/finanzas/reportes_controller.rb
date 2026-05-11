module Finanzas
  class ReportesController < ApplicationController
    before_action :autenticar_usuario
    before_action :requiere_cuenta_financiera_para_finanzas!
    before_action -> { requiere_permiso!(:cooperaciones, :ver) }
    before_action :cargar_contexto_financiero

    def index
      cargar_reporte
    end

    def excel
      cargar_reporte

      archivo = Excel::ReporteFinancieroXlsx.new(
        tipo: @tipo,
        fecha_inicio: @fecha_inicio,
        fecha_fin: @fecha_fin,
        ingresos: @ingresos || [],
        egresos: @egresos || [],
        total_ingresos: @total_ingresos || 0,
        total_egresos: @total_egresos || 0,
        saldo_final: @saldo_final || 0,
        cuenta_financiera: @cuenta_financiera_actual,
        modo_global_por_cuentas: reporte_global_por_cuentas?,
        reportes_por_cuenta: @reportes_por_cuenta || []
      ).render

      send_data archivo,
                filename: nombre_archivo_excel,
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                disposition: "attachment"
    end

    private

    def cargar_contexto_financiero
      @cuentas_financieras = cuentas_financieras_disponibles
      @cuenta_financiera_actual = cuenta_financiera_contexto
    end

    def cargar_reporte
      @tipo = params[:tipo].presence_in(%w[general ingresos egresos]) || "general"
      @fecha_inicio = parsear_fecha(params[:fecha_inicio])
      @fecha_fin = parsear_fecha(params[:fecha_fin])

      if reporte_global_por_cuentas?
        @reportes_por_cuenta = cuentas_financieras_para_reporte.map do |cuenta|
          construir_reporte_para_cuenta(cuenta)
        end
      else
        @ingresos = ingresos_confirmados
        @egresos = egresos_confirmados

        @total_ingresos = @ingresos.sum { |cooperacion| cooperacion.total_esperado.to_d }
        @total_egresos = @egresos.sum { |egreso| egreso.monto.to_d }
        @saldo_final = @total_ingresos - @total_egresos
      end
    end

    def reporte_global_por_cuentas?
      admin_actual? && @cuenta_financiera_actual.blank?
    end

    def cuentas_financieras_para_reporte
      if admin_actual?
        CuentaFinanciera.activas
      elsif finanzas_actual? && usuario_actual.cuenta_financiera.present?
        CuentaFinanciera.where(id: usuario_actual.cuenta_financiera_id)
      else
        CuentaFinanciera.none
      end
    end

    def construir_reporte_para_cuenta(cuenta)
      ingresos = ingresos_confirmados_por_cuenta(cuenta)
      egresos = egresos_confirmados_por_cuenta(cuenta)

      total_ingresos = ingresos.sum { |cooperacion| cooperacion.total_esperado.to_d }
      total_egresos = egresos.sum { |egreso| egreso.monto.to_d }

      {
        cuenta: cuenta,
        ingresos: ingresos,
        egresos: egresos,
        total_ingresos: total_ingresos,
        total_egresos: total_egresos,
        saldo_final: total_ingresos - total_egresos
      }
    end

    def ingresos_confirmados
      base = aplicar_cuenta_financiera(
        Cooperacion.includes(:cuenta_financiera).where(estado: "completada")
      )

      aplicar_rango_confirmacion(base).order(confirmada_at: :desc)
    rescue StandardError
      Cooperacion.none
    end

    def egresos_confirmados
      base = aplicar_cuenta_financiera(
        Egreso.includes(:cuenta_financiera).where(estado: "confirmado")
      )

      aplicar_rango_date(base, :fecha_egreso).ordenados_por_folio
    rescue StandardError
      Egreso.none
    end

    def ingresos_confirmados_por_cuenta(cuenta)
      base = Cooperacion.includes(:cuenta_financiera)
                         .where(estado: "completada", cuenta_financiera_id: cuenta.id)

      aplicar_rango_confirmacion(base).order(confirmada_at: :desc)
    rescue StandardError
      Cooperacion.none
    end

    def egresos_confirmados_por_cuenta(cuenta)
      base = Egreso.includes(:cuenta_financiera)
                   .where(estado: "confirmado", cuenta_financiera_id: cuenta.id)

      aplicar_rango_date(base, :fecha_egreso).ordenados_por_folio
    rescue StandardError
      Egreso.none
    end

    def aplicar_rango_confirmacion(scope)
      return scope unless Cooperacion.column_names.include?("confirmada_at")

      aplicar_rango_datetime(scope, :confirmada_at)
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
      cuenta = @cuenta_financiera_actual&.nombre&.parameterize(separator: "_") || "cuentas_separadas"

      "reporte_financiero_#{@tipo}_#{cuenta}_#{fecha}.xlsx"
    end
  end
end
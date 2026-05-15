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
        ingresos: @ingresos,
        egresos: @egresos,
        total_ingresos: @total_ingresos,
        total_egresos: @total_egresos,
        saldo_final: @saldo_final,
        cuenta_financiera: @cuenta_financiera_actual,
        modo_global_por_cuentas: modo_global_por_cuentas?,
        reportes_por_cuenta: @bloques_cuentas
      ).render

      send_data archivo,
                filename: nombre_archivo_excel,
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                disposition: "attachment"
    end

    def pdf
      cargar_reporte

      archivo = Pdf::ReporteFinancieroPdf.new(
        tipo: @tipo,
        fecha_inicio: @fecha_inicio,
        fecha_fin: @fecha_fin,
        cuenta_financiera_actual: @cuenta_financiera_actual,
        bloques_cuentas: @bloques_cuentas,
        total_ingresos: @total_ingresos,
        total_egresos: @total_egresos,
        saldo_final: @saldo_final,
        generado_por: usuario_actual
      ).render

      send_data archivo,
                filename: nombre_archivo_pdf,
                type: "application/pdf",
                disposition: "inline"
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

      @ingresos = ingresos_confirmados(cooperaciones_base).to_a
      @egresos = egresos_confirmados(egresos_base).to_a

      @total_ingresos = @ingresos.sum { |cooperacion| cooperacion.total_esperado.to_d }
      @total_egresos = @egresos.sum { |egreso| egreso.monto.to_d }
      @saldo_final = @total_ingresos - @total_egresos

      @bloques_cuentas = construir_bloques_por_cuenta
      @reportes_por_cuenta = @bloques_cuentas
    end

    def cooperaciones_base
      aplicar_filtro_cuenta(Cooperacion.all)
    end

    def egresos_base
      aplicar_filtro_cuenta(Egreso.all)
    end

    def aplicar_filtro_cuenta(scope)
      if @cuenta_financiera_actual.present?
        scope.where(cuenta_financiera_id: @cuenta_financiera_actual.id)
      elsif finanzas_actual?
        scope.where(cuenta_financiera_id: usuario_actual.cuenta_financiera_id)
      else
        scope
      end
    end

    def construir_bloques_por_cuenta
      cuentas_para_reporte.map do |cuenta|
        ingresos = ingresos_confirmados(scope_cooperaciones_para(cuenta)).to_a
        egresos = egresos_confirmados(scope_egresos_para(cuenta)).to_a

        total_ingresos = ingresos.sum { |cooperacion| cooperacion.total_esperado.to_d }
        total_egresos = egresos.sum { |egreso| egreso.monto.to_d }

        {
          cuenta: cuenta,
          nombre_cuenta: cuenta&.nombre || "Sin cuenta financiera",
          ingresos: ingresos,
          egresos: egresos,
          total_ingresos: total_ingresos,
          total_egresos: total_egresos,
          saldo_final: total_ingresos - total_egresos
        }
      end
    end

    def cuentas_para_reporte
      return [@cuenta_financiera_actual] if @cuenta_financiera_actual.present?
      return [usuario_actual.cuenta_financiera].compact if finanzas_actual?

      cuentas = CuentaFinanciera.order(:nombre).to_a
      cuentas << nil if existen_movimientos_sin_cuenta?

      cuentas
    end

    def existen_movimientos_sin_cuenta?
      Cooperacion.where(cuenta_financiera_id: nil).exists? ||
        Egreso.where(cuenta_financiera_id: nil).exists?
    end

    def scope_cooperaciones_para(cuenta)
      if cuenta.present?
        Cooperacion.where(cuenta_financiera_id: cuenta.id)
      else
        Cooperacion.where(cuenta_financiera_id: nil)
      end
    end

    def scope_egresos_para(cuenta)
      if cuenta.present?
        Egreso.where(cuenta_financiera_id: cuenta.id)
      else
        Egreso.where(cuenta_financiera_id: nil)
      end
    end

    def ingresos_confirmados(scope)
      base = scope.includes(:cuenta_financiera).where(estado: "completada")

      if Cooperacion.column_names.include?("confirmada_at")
        base = aplicar_rango_datetime(base, :confirmada_at)
        base.order(confirmada_at: :desc)
      else
        base.order(created_at: :desc)
      end
    rescue StandardError
      Cooperacion.none
    end

    def egresos_confirmados(scope)
      base = scope.includes(:cuenta_financiera).where(estado: "confirmado")
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

    def modo_global_por_cuentas?
      admin_actual? && @cuenta_financiera_actual.blank?
    end

    def nombre_archivo_excel
      fecha = Time.current.strftime("%Y%m%d_%H%M%S")
      "reporte_financiero_#{@tipo}_#{fecha}.xlsx"
    end

    def nombre_archivo_pdf
      fecha = Time.current.strftime("%Y%m%d_%H%M%S")
      "reporte_financiero_#{@tipo}_#{fecha}.pdf"
    end
  end
end
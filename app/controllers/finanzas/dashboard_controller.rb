module Finanzas
  class DashboardController < ApplicationController
    before_action :autenticar_usuario
    before_action :requiere_cuenta_financiera_para_finanzas!
    before_action -> { requiere_permiso!(:cooperaciones, :ver) }
    before_action :cargar_contexto_financiero

    def index
      if dashboard_global_por_cuentas?
        @dashboard_por_cuenta = cuentas_financieras_para_dashboard.map do |cuenta|
          resumen_para_cuenta(cuenta)
        end
      else
        @dashboard_cuenta = resumen_para_cuenta(@cuenta_financiera_actual)
        asignar_variables_dashboard(@dashboard_cuenta)
      end
    end

    private

    def cargar_contexto_financiero
      @cuentas_financieras = cuentas_financieras_disponibles
      @cuenta_financiera_actual = cuenta_financiera_contexto
    end

    def dashboard_global_por_cuentas?
      admin_actual? && @cuenta_financiera_actual.blank?
    end

    def cuentas_financieras_para_dashboard
      if admin_actual?
        CuentaFinanciera.activas
      elsif finanzas_actual? && usuario_actual.cuenta_financiera.present?
        CuentaFinanciera.where(id: usuario_actual.cuenta_financiera_id)
      else
        CuentaFinanciera.none
      end
    end

    def resumen_para_cuenta(cuenta)
      cooperaciones = Cooperacion.where(cuenta_financiera_id: cuenta.id)
      egresos = Egreso.where(cuenta_financiera_id: cuenta.id)

      total_esperado = calcular_total_esperado_de(cooperaciones)
      total_confirmado = calcular_total_confirmado_de(cooperaciones)
      monto_egresos_confirmados = calcular_monto_egresos_confirmados_de(egresos)
      saldo_financiero = total_confirmado.to_d - monto_egresos_confirmados.to_d

      {
        cuenta: cuenta,

        total_cooperaciones: cooperaciones.count,
        cooperaciones_activas: cooperaciones.where(estado: "activa").count,
        cooperaciones_completadas: cooperaciones.where(estado: "completada").count,
        total_esperado: total_esperado,
        total_confirmado: total_confirmado,

        total_egresos: egresos.count,
        egresos_registrados: egresos.where(estado: "registrado").count,
        egresos_confirmados: egresos.where(estado: "confirmado").count,
        egresos_cancelados: egresos.where(estado: "cancelado").count,
        monto_egresos_confirmados: monto_egresos_confirmados,
        saldo_financiero: saldo_financiero,

        ultimos_egresos: egresos.ordenados_por_folio.limit(5)
      }
    end

    def asignar_variables_dashboard(resumen)
      @total_cooperaciones = resumen[:total_cooperaciones]
      @cooperaciones_activas = resumen[:cooperaciones_activas]
      @cooperaciones_completadas = resumen[:cooperaciones_completadas]

      @total_esperado = resumen[:total_esperado]
      @total_confirmado = resumen[:total_confirmado]

      @total_egresos = resumen[:total_egresos]
      @egresos_registrados = resumen[:egresos_registrados]
      @egresos_confirmados = resumen[:egresos_confirmados]
      @egresos_cancelados = resumen[:egresos_cancelados]

      @monto_egresos_confirmados = resumen[:monto_egresos_confirmados]
      @saldo_financiero = resumen[:saldo_financiero]

      @ultimos_egresos = resumen[:ultimos_egresos]
    end

    def calcular_total_esperado_de(cooperaciones)
      return 0 unless Cooperacion.method_defined?(:total_esperado)

      cooperaciones.sum { |cooperacion| cooperacion.total_esperado.to_d }
    rescue StandardError
      0
    end

    def calcular_total_confirmado_de(cooperaciones)
      return 0 unless Cooperacion.column_names.include?("estado")
      return 0 unless Cooperacion.method_defined?(:total_esperado)

      cooperaciones.where(estado: "completada").sum do |cooperacion|
        cooperacion.total_esperado.to_d
      end
    rescue StandardError
      0
    end

    def calcular_monto_egresos_confirmados_de(egresos)
      return 0 unless Egreso.column_names.include?("estado")
      return 0 unless Egreso.column_names.include?("monto")

      egresos.where(estado: "confirmado").sum(:monto).to_d
    rescue StandardError
      0
    end
  end
end
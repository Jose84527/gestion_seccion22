module Finanzas
  class DashboardController < ApplicationController
    before_action :autenticar_usuario
    before_action -> { requiere_permiso!(:cooperaciones, :ver) }

    def index
      @total_cooperaciones = Cooperacion.count

      @cooperaciones_activas = contar_cooperaciones_activas
      @cooperaciones_completadas = contar_cooperaciones_completadas

      @total_esperado = calcular_total_esperado
      @total_confirmado = calcular_total_confirmado

      @total_egresos = Egreso.count
      @egresos_registrados = contar_egresos_por_estado("registrado")
      @egresos_confirmados = contar_egresos_por_estado("confirmado")
      @egresos_cancelados = contar_egresos_por_estado("cancelado")

      @monto_egresos_confirmados = calcular_monto_egresos_confirmados
      @saldo_financiero = calcular_saldo_financiero

      @ultimos_egresos = Egreso.ordenados_por_folio.limit(5)
    end

    private

    def contar_cooperaciones_activas
      if Cooperacion.column_names.include?("estado")
        Cooperacion.where(estado: "activa").count
      elsif Cooperacion.column_names.include?("activa")
        Cooperacion.where(activa: true).count
      else
        0
      end
    end

    def contar_cooperaciones_completadas
      return 0 unless Cooperacion.column_names.include?("estado")

      Cooperacion.where(estado: "completada").count
    end

    def calcular_total_esperado
      return 0 unless Cooperacion.method_defined?(:total_esperado)

      Cooperacion.all.sum { |cooperacion| cooperacion.total_esperado.to_d }
    rescue StandardError
      0
    end

    def calcular_total_confirmado
      return 0 unless Cooperacion.column_names.include?("estado")
      return 0 unless Cooperacion.method_defined?(:total_esperado)

      Cooperacion.where(estado: "completada").sum { |cooperacion| cooperacion.total_esperado.to_d }
    rescue StandardError
      0
    end

    def contar_egresos_por_estado(estado)
      return 0 unless Egreso.column_names.include?("estado")

      Egreso.where(estado: estado).count
    rescue StandardError
      0
    end

    def calcular_monto_egresos_confirmados
      return 0 unless Egreso.column_names.include?("estado")
      return 0 unless Egreso.column_names.include?("monto")

      Egreso.where(estado: "confirmado").sum(:monto).to_d
    rescue StandardError
      0
    end

    def calcular_saldo_financiero
      @total_confirmado.to_d - @monto_egresos_confirmados.to_d
    rescue StandardError
      0
    end
  end
end
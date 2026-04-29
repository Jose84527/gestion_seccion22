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
      if Cooperacion.column_names.include?("estado")
        Cooperacion.where(estado: "completada").count
      else
        0
      end
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
  end
end
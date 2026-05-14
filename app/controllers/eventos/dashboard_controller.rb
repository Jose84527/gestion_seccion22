module Eventos
  class DashboardController < ApplicationController
    before_action :autenticar_usuario
    before_action -> { requiere_permiso!(:eventos, :ver) }

    def index
      cargar_indicadores_dashboard
      cargar_proximos_eventos
      cargar_ranking_top
    end

    def reporte_participacion_pdf
      datos = datos_reporte_participacion

      pdf = Pdf::EventosParticipacionReportePdf.new(
        trabajadores: datos[:trabajadores],
        total_eventos_confirmados: datos[:total_eventos_confirmados],
        trabajadores_activos: datos[:trabajadores_activos],
        puntos_posibles_por_trabajador: datos[:puntos_posibles_por_trabajador],
        puntos_acumulados: datos[:puntos_acumulados],
        puntos_posibles_generales: datos[:puntos_posibles_generales],
        porcentaje_participacion_general: datos[:porcentaje_participacion_general]
      ).render

      send_data pdf,
                filename: "reporte_participacion_eventos_#{Time.current.strftime('%Y%m%d_%H%M%S')}.pdf",
                type: "application/pdf",
                disposition: "inline"
    end

    private

    def cargar_indicadores_dashboard
      @total_eventos = Evento.count
      @eventos_programados = Evento.where(estado: "programado").count
      @eventos_confirmados = Evento.where(estado: "confirmado").count
      @eventos_cancelados = Evento.where(estado: "cancelado").count

      @puntos_acumulados = puntos_acumulados_confirmados
      @trabajadores_activos = trabajadores_activos_count
      @puntos_posibles_por_trabajador = puntos_posibles_por_trabajador
      @puntos_posibles_generales = @trabajadores_activos * @puntos_posibles_por_trabajador

      @porcentaje_participacion_general = calcular_porcentaje(
        @puntos_acumulados,
        @puntos_posibles_generales
      )
    end

    def cargar_proximos_eventos
      @proximos_eventos = Evento
                          .where(estado: "programado")
                          .where("fecha_inicio >= ?", Time.current)
                          .order(:fecha_inicio)
                          .limit(5)
    end

    def cargar_ranking_top
      @ranking_trabajadores = trabajadores_con_participacion
                              .limit(10)
    end

    def datos_reporte_participacion
      trabajadores = trabajadores_con_participacion

      trabajadores_activos = trabajadores_activos_count
      puntos_posibles_trabajador = puntos_posibles_por_trabajador
      puntos_acumulados = puntos_acumulados_confirmados
      puntos_posibles_generales = trabajadores_activos * puntos_posibles_trabajador

      {
        trabajadores: trabajadores,
        total_eventos_confirmados: Evento.where(estado: "confirmado").count,
        trabajadores_activos: trabajadores_activos,
        puntos_posibles_por_trabajador: puntos_posibles_trabajador,
        puntos_acumulados: puntos_acumulados,
        puntos_posibles_generales: puntos_posibles_generales,
        porcentaje_participacion_general: calcular_porcentaje(
          puntos_acumulados,
          puntos_posibles_generales
        )
      }
    end

    def trabajadores_con_participacion
      Trabajador
        .where(estado_trabajador: "activo")
        .left_joins(:evento_asistencias)
        .joins("LEFT JOIN eventos ON eventos.id = evento_asistencias.evento_id")
        .select(
          "trabajadores.*",
          "COUNT(DISTINCT CASE WHEN eventos.estado = 'confirmado' THEN evento_asistencias.evento_id END) AS eventos_asistidos_count",
          "COALESCE(SUM(CASE WHEN eventos.estado = 'confirmado' THEN evento_asistencias.puntaje_asignado ELSE 0 END), 0) AS puntos_acumulados"
        )
        .group("trabajadores.id")
        .order(
          Arel.sql(
            "puntos_acumulados DESC, eventos_asistidos_count DESC, trabajadores.apellido_paterno ASC, trabajadores.apellido_materno ASC, trabajadores.nombres ASC"
          )
        )
    end

    def trabajadores_activos_count
      Trabajador.where(estado_trabajador: "activo").count
    end

    def puntos_posibles_por_trabajador
      Evento.where(estado: "confirmado").sum(:puntaje).to_i
    end

    def puntos_acumulados_confirmados
      EventoAsistencia
        .joins(:evento)
        .where(eventos: { estado: "confirmado" })
        .sum(:puntaje_asignado)
        .to_i
    end

    def calcular_porcentaje(valor, total)
      return 0.to_d unless total.to_d.positive?

      (valor.to_d / total.to_d) * 100
    end
  end
end
class HomeController < ApplicationController
  before_action :autenticar_usuario

  def index
    redirect_to menu_path if admin_actual?
  end

  def menu
    unless admin_actual?
      return redirect_to root_path, alert: "No tienes permiso para acceder al dashboard general"
    end

    cargar_dashboard_admin
  end

  private

  def cargar_dashboard_admin
    @total_trabajadores_activos = Trabajador.where(estado_trabajador: "activo").count

    @recaudacion_6_meses = Cooperacion
                           .where(estado: "completada")
                           .where(confirmada_at: 6.months.ago..Time.current)
                           .includes(:cooperacion_conceptos, :cooperacion_condonados, :cooperacion_detalles_confirmados)
                           .to_a
                           .sum { |cooperacion| cooperacion.total_esperado.to_d }

    @proximos_eventos_count = Evento
                              .where(estado: "programado")
                              .where("fecha_inicio >= ?", Time.current)
                              .count

    @puntos_posibles_por_trabajador = Evento
                                      .where(estado: "confirmado")
                                      .sum(:puntaje)
                                      .to_i

    @puntos_acumulados_eventos = EventoAsistencia
                                 .joins(:evento)
                                 .where(eventos: { estado: "confirmado" })
                                 .sum(:puntaje_asignado)
                                 .to_i

    puntos_posibles_generales = @total_trabajadores_activos * @puntos_posibles_por_trabajador

    @porcentaje_participacion_general =
      if puntos_posibles_generales.positive?
        (@puntos_acumulados_eventos.to_d / puntos_posibles_generales.to_d) * 100
      else
        0.to_d
      end

    @ultimas_cooperaciones = Cooperacion
                             .includes(:cooperacion_conceptos, :cooperacion_condonados, :cooperacion_detalles_confirmados)
                             .order(created_at: :desc)
                             .limit(5)

    @ultimos_egresos = Egreso
                       .order(created_at: :desc)
                       .limit(5)

    @proximos_eventos = Evento
                        .where(estado: "programado")
                        .where("fecha_inicio >= ?", Time.current)
                        .order(:fecha_inicio)
                        .limit(5)

    @top_trabajadores_participacion = Trabajador
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
                                      .limit(5)
  end
end
# Be sure to restart your server when you modify this file.

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "historial", "historiales"
  inflect.irregular "trabajador", "trabajadores"
  inflect.irregular "usuario", "usuarios"
  inflect.irregular "actividad", "actividades"
  inflect.irregular "cooperacion", "cooperaciones"

  inflect.irregular "asistencia_actividad", "asistencia_actividades"
  inflect.irregular "concepto07_nivel", "concepto07_niveles"
  inflect.irregular "cooperacion_afiliado", "cooperacion_afiliados"
  inflect.irregular "cooperacion_concepto07_config", "cooperacion_concepto07_configs"
end
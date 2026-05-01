module HistorialesHelper
  def nombre_modulo_historial(modulo)
    case modulo.to_s
    when "trabajadores"
      "Trabajadores"
    when "usuarios"
      "Usuarios"
    when "cooperaciones"
      "Cooperaciones"
    when "egresos"
      "Egresos"
    when "concepto07_niveles"
      "Categorías"
    when "historial"
      "Historial"
    else
      modulo.to_s.humanize
    end
  end
end
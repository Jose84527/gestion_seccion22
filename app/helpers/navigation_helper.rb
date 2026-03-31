module NavigationHelper
  def sidebar_items
    [
      { clave: :dashboard, etiqueta: "Dashboard SG", icono: "⌂", ruta: menu_path },
      { clave: :trabajadores, etiqueta: "Trabajadores", icono: "👥", ruta: nil },
      { clave: :detalle_trabajador, etiqueta: "Detalle trabajador", icono: "🪪", ruta: nil },
      { clave: :cooperaciones, etiqueta: "Cooperaciones", icono: "💰", ruta: nil },
      { clave: :nueva_cooperacion, etiqueta: "Nueva cooperación", icono: "＋", ruta: nil },
      { clave: :eventos, etiqueta: "Eventos", icono: "📅", ruta: nil },
      { clave: :detalle_evento, etiqueta: "Detalle evento", icono: "📌", ruta: nil },
      { clave: :registro_asistencia, etiqueta: "Registro asistencia", icono: "📝", ruta: nil },
      { clave: :reporte_participacion, etiqueta: "Reporte participación", icono: "📊", ruta: nil },
      { clave: :generar_constancia, etiqueta: "Generar constancia", icono: "📄", ruta: nil },
      { clave: :usuarios, etiqueta: "Usuarios", icono: "⚙", ruta: nil }
    ]
  end

  def clase_item_sidebar(item)
    clases = ["sidebar__item"]

    if item[:ruta].present?
      clases << "is-active" if current_page?(item[:ruta])
    else
      clases << "is-disabled"
    end

    clases.join(" ")
  end

  def iniciales_usuario_actual
    nombre = usuario_actual&.nombre_usuario.to_s.strip
    return "US" if nombre.blank?

    nombre.first(2).upcase
  end
end
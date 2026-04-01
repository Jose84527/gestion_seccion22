module NavigationHelper
  def sidebar_items
    items = [
      { clave: :dashboard, modulo: :dashboard, etiqueta: "Dashboard SG", icono: "⌂", ruta: menu_path },
      { clave: :trabajadores, modulo: :trabajadores, etiqueta: "Trabajadores", icono: "👥", ruta: trabajadores_path },
      { clave: :detalle_trabajador, modulo: :trabajadores, etiqueta: "Detalle trabajador", icono: "🪪", ruta: nil },
      { clave: :cooperaciones, modulo: :cooperaciones, etiqueta: "Cooperaciones", icono: "💰", ruta: nil },
      { clave: :nueva_cooperacion, modulo: :cooperaciones, etiqueta: "Nueva cooperación", icono: "＋", ruta: nil },
      { clave: :eventos, modulo: :eventos, etiqueta: "Eventos", icono: "📅", ruta: nil },
      { clave: :detalle_evento, modulo: :eventos, etiqueta: "Detalle evento", icono: "📌", ruta: nil },
      { clave: :registro_asistencia, modulo: :eventos, etiqueta: "Registro asistencia", icono: "📝", ruta: nil },
      { clave: :reporte_participacion, modulo: :eventos, etiqueta: "Reporte participación", icono: "📊", ruta: nil },
      { clave: :generar_constancia, modulo: :eventos, etiqueta: "Generar constancia", icono: "📄", ruta: nil },
      { clave: :usuarios, modulo: :usuarios, etiqueta: "Usuarios", icono: "⚙", ruta: nil },
      { clave: :historial, modulo: :historial, etiqueta: "Historial", icono: "🕘", ruta: historiales_path }
    ]

    items.select { |item| puede_ver_modulo?(item[:modulo]) }
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
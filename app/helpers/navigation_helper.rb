module NavigationHelper
  def sidebar_items
    items = [
      { clave: :dashboard, modulo: :dashboard, etiqueta: "Dashboard SG", icono: "⌂", ruta: menu_path },

      { clave: :trabajadores, modulo: :trabajadores, etiqueta: "Trabajadores", icono: "👥", ruta: trabajadores_path },
      { clave: :detalle_trabajador, modulo: :trabajadores, etiqueta: "Detalle trabajador", icono: "🪪", ruta: nil },

      { clave: :conceptos07, modulo: :conceptos07, etiqueta: "Categorías", icono: "🏷", ruta: concepto07_niveles_path },

      { clave: :finanzas, modulo: :cooperaciones, etiqueta: "Finanzas", icono: "💼", ruta: finanzas_path, tipo: :grupo },
      { clave: :finanzas_dashboard, modulo: :cooperaciones, etiqueta: "Dashboard financiero", icono: "↳", ruta: finanzas_path, tipo: :subitem },
      { clave: :nueva_cooperacion, modulo: :cooperaciones, etiqueta: "Nueva cooperación", icono: "↳", ruta: new_cooperacion_path, tipo: :subitem },
      { clave: :control_cooperaciones, modulo: :cooperaciones, etiqueta: "Control de cooperaciones", icono: "↳", ruta: cooperaciones_path, tipo: :subitem },
      { clave: :egresos, modulo: :cooperaciones, etiqueta: "Egresos", icono: "↳", ruta: egresos_path, tipo: :subitem },

      { clave: :eventos, modulo: :eventos, etiqueta: "Eventos", icono: "📅", ruta: nil },
      { clave: :detalle_evento, modulo: :eventos, etiqueta: "Detalle evento", icono: "📌", ruta: nil },
      { clave: :registro_asistencia, modulo: :eventos, etiqueta: "Registro asistencia", icono: "📝", ruta: nil },
      { clave: :reporte_participacion, modulo: :eventos, etiqueta: "Reporte participación", icono: "📊", ruta: nil },
      { clave: :generar_constancia, modulo: :eventos, etiqueta: "Generar constancia", icono: "📄", ruta: nil },

      { clave: :usuarios, modulo: :usuarios, etiqueta: "Usuarios", icono: "⚙", ruta: usuarios_path },
      { clave: :historial, modulo: :historial, etiqueta: "Historial", icono: "🕘", ruta: historiales_path }
    ]

    items.select { |item| puede_ver_modulo?(item[:modulo]) }
  end

  def clase_item_sidebar(item)
    clases = ["sidebar__item"]

    clases << "sidebar__item--group" if item[:tipo] == :grupo
    clases << "sidebar__item--subitem" if item[:tipo] == :subitem

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
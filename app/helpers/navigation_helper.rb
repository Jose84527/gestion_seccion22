module NavigationHelper
  def sidebar_items
    items = [
      { clave: :dashboard, modulo: :dashboard, etiqueta: "Dashboard SG", icono: "⌂", ruta: menu_path },

      { clave: :trabajadores, modulo: :trabajadores, etiqueta: "Trabajadores", icono: "👥", ruta: trabajadores_path },

      { clave: :conceptos07, modulo: :conceptos07, etiqueta: "Categorías", icono: "🏷", ruta: concepto07_niveles_path },

      { clave: :finanzas, modulo: :cooperaciones, etiqueta: "Finanzas", icono: "💼", ruta: finanzas_path, tipo: :grupo }
    ]

    items.concat(finanzas_subitems) if finanzas_activa?

    items << {
      clave: :eventos,
      modulo: :eventos,
      etiqueta: "Eventos",
      icono: "📅",
      ruta: eventos_dashboard_path,
      tipo: :grupo
    }

    items.concat(eventos_subitems) if eventos_activa?

    items.concat(
      [
        { clave: :usuarios, modulo: :usuarios, etiqueta: "Usuarios", icono: "⚙", ruta: usuarios_path },
        { clave: :historial, modulo: :historial, etiqueta: "Historial", icono: "🕘", ruta: historiales_path }
      ]
    )

    items.select { |item| puede_ver_modulo?(item[:modulo]) }
  end

  def finanzas_subitems
    [
      {
        clave: :finanzas_dashboard,
        modulo: :cooperaciones,
        etiqueta: "Dashboard financiero",
        icono: "↳",
        ruta: finanzas_path,
        tipo: :subitem
      },
      {
        clave: :nueva_cooperacion,
        modulo: :cooperaciones,
        etiqueta: "Nueva cooperación",
        icono: "↳",
        ruta: new_cooperacion_path,
        tipo: :subitem
      },
      {
        clave: :control_cooperaciones,
        modulo: :cooperaciones,
        etiqueta: "Control de cooperaciones",
        icono: "↳",
        ruta: cooperaciones_path,
        tipo: :subitem
      },
      {
        clave: :egresos,
        modulo: :cooperaciones,
        etiqueta: "Egresos",
        icono: "↳",
        ruta: egresos_path,
        tipo: :subitem
      },
      {
        clave: :reportes_financieros,
        modulo: :cooperaciones,
        etiqueta: "Reportes financieros",
        icono: "↳",
        ruta: finanzas_reportes_path,
        tipo: :subitem
      }
    ]
  end

  def eventos_subitems
    [
      {
        clave: :eventos_dashboard,
        modulo: :eventos,
        etiqueta: "Dashboard de eventos",
        icono: "↳",
        ruta: eventos_dashboard_path,
        tipo: :subitem
      },
      {
        clave: :nuevo_evento,
        modulo: :eventos,
        etiqueta: "Nuevo evento",
        icono: "↳",
        ruta: new_evento_path,
        tipo: :subitem
      },
      {
        clave: :control_eventos,
        modulo: :eventos,
        etiqueta: "Control de eventos",
        icono: "↳",
        ruta: eventos_path,
        tipo: :subitem
      }
    ]
  end

  def finanzas_activa?
    rutas_finanzas = [
      finanzas_path,
      cooperaciones_path,
      egresos_path,
      finanzas_reportes_path
    ]

    rutas_finanzas.any? do |ruta|
      request.path == ruta || request.path.start_with?("#{ruta}/")
    end
  end

  def eventos_activa?
    rutas_eventos = [
      eventos_dashboard_path,
      eventos_path
    ]

    rutas_eventos.any? do |ruta|
      request.path == ruta || request.path.start_with?("#{ruta}/")
    end
  end

  def clase_item_sidebar(item)
    clases = ["sidebar__item"]

    clases << "sidebar__item--group" if item[:tipo] == :grupo
    clases << "sidebar__item--subitem" if item[:tipo] == :subitem

    if item[:clave] == :finanzas
      clases << "is-active" if finanzas_activa?
      clases << "is-open" if finanzas_activa?
    elsif item[:clave] == :eventos
      clases << "is-active" if eventos_activa?
      clases << "is-open" if eventos_activa?
    elsif item[:ruta].present?
      clases << "is-active" if item_activo?(item)
    else
      clases << "is-disabled"
    end

    clases.join(" ")
  end

  def item_activo?(item)
    case item[:clave]
    when :finanzas_dashboard
      current_page?(finanzas_path)
    when :nueva_cooperacion
      current_page?(new_cooperacion_path)
    when :control_cooperaciones
      request.path.start_with?(cooperaciones_path) && !current_page?(new_cooperacion_path)
    when :egresos
      request.path.start_with?(egresos_path)
    when :reportes_financieros
      request.path.start_with?(finanzas_reportes_path)

    when :eventos_dashboard
      current_page?(eventos_dashboard_path)
    when :nuevo_evento
      current_page?(new_evento_path)
    when :control_eventos
      request.path.start_with?(eventos_path) &&
        !current_page?(new_evento_path) &&
        !request.path.start_with?(eventos_dashboard_path)

    else
      current_page?(item[:ruta])
    end
  end

  def iniciales_usuario_actual
    nombre = usuario_actual&.nombre_usuario.to_s.strip
    return "US" if nombre.blank?

    nombre.first(2).upcase
  end
end
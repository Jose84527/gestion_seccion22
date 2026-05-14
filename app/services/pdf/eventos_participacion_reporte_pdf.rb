require "prawn"

module Pdf
  class EventosParticipacionReportePdf
    COLUMNAS = [
      { key: :ranking, label: "No.", width: 24, align: :center },
      { key: :trabajador, label: "Trabajador", width: 125, align: :left },
      { key: :tipo, label: "Tipo", width: 60, align: :left },
      { key: :sexo, label: "Sexo", width: 42, align: :left },
      { key: :rfc, label: "RFC", width: 72, align: :left },
      { key: :clave_cobro, label: "Clave", width: 50, align: :left },
      { key: :eventos, label: "Eventos", width: 42, align: :center },
      { key: :puntos, label: "Puntos", width: 50, align: :center },
      { key: :porcentaje, label: "%", width: 38, align: :center },
      { key: :nivel, label: "Nivel", width: 53, align: :left }
    ].freeze

    def initialize(
      trabajadores:,
      total_eventos_confirmados:,
      trabajadores_activos:,
      puntos_posibles_por_trabajador:,
      puntos_acumulados:,
      puntos_posibles_generales:,
      porcentaje_participacion_general:
    )
      @trabajadores = trabajadores
      @total_eventos_confirmados = total_eventos_confirmados.to_i
      @trabajadores_activos = trabajadores_activos.to_i
      @puntos_posibles_por_trabajador = puntos_posibles_por_trabajador.to_i
      @puntos_acumulados = puntos_acumulados.to_i
      @puntos_posibles_generales = puntos_posibles_generales.to_i
      @porcentaje_participacion_general = porcentaje_participacion_general.to_d
    end

    def render
      Prawn::Document.new(page_size: "LETTER", margin: 28) do |pdf|
        @pdf = pdf

        encabezado
        bloque_datos_generales
        bloque_criterio
        tabla_trabajadores
        pie_de_pagina
      end.render
    end

    private

    def encabezado
      @pdf.fill_color "000000"

      @pdf.text limpiar("DELEGACIÓN SINDICAL D-II-11"),
                size: 12,
                style: :bold,
                align: :center

      @pdf.text limpiar("INSTITUTO TECNOLÓGICO DE OAXACA"),
                size: 11,
                style: :bold,
                align: :center

      @pdf.move_down 8

      @pdf.text limpiar("REPORTE GENERAL DE PARTICIPACIÓN EN EVENTOS"),
                size: 14,
                style: :bold,
                align: :center

      @pdf.move_down 4

      @pdf.text limpiar("Fecha de emisión: #{Time.current.strftime('%d/%m/%Y %H:%M')}"),
                size: 8,
                align: :right

      @pdf.move_down 8
      @pdf.stroke_color "333333"
      @pdf.stroke_horizontal_rule
      @pdf.stroke_color "000000"
      @pdf.move_down 12
    end

    def bloque_datos_generales
      @pdf.text limpiar("I. Indicadores generales"),
                size: 10,
                style: :bold

      @pdf.move_down 6

      datos = [
        ["Eventos confirmados", @total_eventos_confirmados.to_s],
        ["Trabajadores activos", @trabajadores_activos.to_s],
        ["Puntos máximos posibles por trabajador", @puntos_posibles_por_trabajador.to_s],
        ["Puntos acumulados por la delegación", @puntos_acumulados.to_s],
        ["Puntos máximos posibles generales", @puntos_posibles_generales.to_s],
        ["Porcentaje general de participación", "#{formato_porcentaje(@porcentaje_participacion_general)}%"]
      ]

      ancho_etiqueta = 360
      ancho_valor = 140
      altura = 18
      x = @pdf.bounds.left
      y = @pdf.cursor

      datos.each do |etiqueta, valor|
        dibujar_celda_indicador(x, y, ancho_etiqueta, altura, etiqueta, :etiqueta)
        dibujar_celda_indicador(x + ancho_etiqueta, y, ancho_valor, altura, valor, :valor)

        y -= altura
      end

      @pdf.move_cursor_to(y - 8)
      @pdf.move_down 8
    end

    def dibujar_celda_indicador(x, y, ancho, alto, texto, tipo)
      color_fondo = tipo == :etiqueta ? "EFEFEF" : "FFFFFF"
      estilo = tipo == :etiqueta ? :bold : :normal

      @pdf.fill_color color_fondo
      @pdf.fill_rectangle [x, y], ancho, alto

      @pdf.stroke_color "BBBBBB"
      @pdf.stroke_rectangle [x, y], ancho, alto

      @pdf.fill_color "000000"
      @pdf.text_box limpiar(texto),
                    at: [x + 5, y - 5],
                    width: ancho - 10,
                    height: alto - 4,
                    size: 8,
                    style: estilo,
                    overflow: :shrink_to_fit,
                    min_font_size: 6

      @pdf.fill_color "000000"
      @pdf.stroke_color "000000"
    end

    def bloque_criterio
      @pdf.move_down 6

      @pdf.text limpiar("II. Criterio de cálculo"),
                size: 10,
                style: :bold

      @pdf.move_down 4

      @pdf.text limpiar(
        "El porcentaje de participación se calcula comparando los puntos acumulados contra los puntos máximos posibles. " \
        "Los puntos máximos posibles por trabajador corresponden a la suma del puntaje de todos los eventos confirmados. " \
        "El nivel de participación individual se obtiene dividiendo los puntos acumulados de cada trabajador entre dichos puntos máximos posibles."
      ),
                size: 8,
                leading: 2,
                align: :justify

      @pdf.move_down 12
    end

    def tabla_trabajadores
      @pdf.text limpiar("III. Relación general de participación por trabajador"),
                size: 10,
                style: :bold

      @pdf.move_down 6

      dibujar_encabezado_tabla

      if @trabajadores.blank?
        @pdf.move_down 10
        @pdf.text limpiar("No hay trabajadores activos para mostrar en el reporte."),
                  size: 9
        return
      end

      @trabajadores.each_with_index do |trabajador, index|
        nueva_pagina_si_es_necesario
        dibujar_fila_trabajador(trabajador, index + 1)
      end
    end

    def dibujar_encabezado_tabla
      altura = 22
      x = @pdf.bounds.left
      y = @pdf.cursor

      @pdf.fill_color "FFFFFF"
      @pdf.fill_rectangle [x, y], ancho_total_tabla, altura

      @pdf.stroke_color "000000"
      @pdf.stroke_rectangle [x, y], ancho_total_tabla, altura

      @pdf.fill_color "000000"

      x_actual = x

      COLUMNAS.each do |columna|
        @pdf.text_box limpiar(columna[:label]),
                      at: [x_actual + 2, y - 6],
                      width: columna[:width] - 4,
                      height: altura,
                      size: 6.5,
                      style: :bold,
                      align: columna[:align],
                      overflow: :shrink_to_fit,
                      min_font_size: 5

        x_actual += columna[:width]
      end

      @pdf.move_down altura
      @pdf.stroke_color "000000"
    end

    def dibujar_fila_trabajador(trabajador, ranking)
      altura = 30
      x = @pdf.bounds.left
      y = @pdf.cursor

      puntos = trabajador.puntos_acumulados.to_i
      eventos = trabajador.eventos_asistidos_count.to_i
      porcentaje = porcentaje_trabajador(puntos)
      nivel = nivel_participacion(porcentaje)

      valores = {
        ranking: ranking.to_s,
        trabajador: trabajador.nombre_completo,
        tipo: trabajador.tipo_trabajador&.humanize || "-",
        sexo: trabajador.sexo&.humanize || "-",
        rfc: trabajador.rfc,
        clave_cobro: trabajador.clave_cobro,
        eventos: eventos.to_s,
        puntos: "#{puntos}/#{@puntos_posibles_por_trabajador}",
        porcentaje: "#{formato_porcentaje(porcentaje)}%",
        nivel: nivel
      }

      @pdf.fill_color "FFFFFF"
      @pdf.fill_rectangle [x, y], ancho_total_tabla, altura

      @pdf.stroke_color "D0D0D0"
      @pdf.stroke_rectangle [x, y], ancho_total_tabla, altura

      @pdf.fill_color "000000"

      x_actual = x

      COLUMNAS.each do |columna|
        @pdf.text_box limpiar(valores[columna[:key]].to_s),
                      at: [x_actual + 2, y - 8],
                      width: columna[:width] - 4,
                      height: altura - 4,
                      size: 6.2,
                      style: :normal,
                      align: columna[:align],
                      overflow: :shrink_to_fit,
                      min_font_size: 4.8

        x_actual += columna[:width]
      end

      @pdf.move_down altura

      @pdf.fill_color "000000"
      @pdf.stroke_color "000000"
    end

    def nueva_pagina_si_es_necesario
      return unless @pdf.cursor < 65

      @pdf.start_new_page
      encabezado_continuacion
      dibujar_encabezado_tabla
    end

    def encabezado_continuacion
      @pdf.text limpiar("REPORTE GENERAL DE PARTICIPACIÓN EN EVENTOS"),
                size: 11,
                style: :bold,
                align: :center

      @pdf.text limpiar("Continuación de la relación general de participación"),
                size: 8,
                align: :center

      @pdf.move_down 10
    end

    def pie_de_pagina
      total_paginas = @pdf.page_count

      (1..total_paginas).each do |numero_pagina|
        @pdf.go_to_page(numero_pagina)

        @pdf.fill_color "000000"
        @pdf.stroke_color "999999"

        @pdf.bounding_box([@pdf.bounds.left, 20], width: @pdf.bounds.width, height: 16) do
          @pdf.stroke_horizontal_rule
          @pdf.move_down 3

          @pdf.text limpiar("Sistema de Gestión Sindical · Reporte institucional de participación"),
                    size: 7,
                    align: :left

          @pdf.text limpiar("Página #{numero_pagina} de #{total_paginas}"),
                    size: 7,
                    align: :right
        end

        @pdf.stroke_color "000000"
      end

      @pdf.go_to_page(total_paginas)
    end

    def porcentaje_trabajador(puntos)
      return 0.to_d unless @puntos_posibles_por_trabajador.positive?

      (puntos.to_d / @puntos_posibles_por_trabajador.to_d) * 100
    end

    def nivel_participacion(porcentaje)
      case porcentaje.to_d
      when 90..100
        "Excelente"
      when 70...90
        "Alta"
      when 40...70
        "Media"
      when 1...40
        "Baja"
      else
        "Sin participación"
      end
    end

    def formato_porcentaje(valor)
      format("%.1f", valor.to_d)
    end

    def ancho_total_tabla
      COLUMNAS.sum { |columna| columna[:width] }
    end

    def limpiar(texto)
      texto.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?")
    end
  end
end
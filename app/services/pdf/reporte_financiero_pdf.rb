require "prawn"

module Pdf
  class ReporteFinancieroPdf
    COLOR_TITULO = "000000".freeze
    COLOR_SUBTITULO = "5B4636".freeze
    COLOR_LINEA = "B8A89B".freeze
    COLOR_ENCABEZADO_TABLA = "EED9C9".freeze
    COLOR_BORDE = "D8C8BB".freeze
    COLOR_FONDO_RESUMEN = "F8F3EF".freeze

    def initialize(
      tipo:,
      fecha_inicio:,
      fecha_fin:,
      cuenta_financiera_actual:,
      bloques_cuentas:,
      total_ingresos:,
      total_egresos:,
      saldo_final:,
      generado_por:
    )
      @tipo = tipo
      @fecha_inicio = fecha_inicio
      @fecha_fin = fecha_fin
      @cuenta_financiera_actual = cuenta_financiera_actual
      @bloques_cuentas = Array(bloques_cuentas)
      @total_ingresos = total_ingresos.to_d
      @total_egresos = total_egresos.to_d
      @saldo_final = saldo_final.to_d
      @generado_por = generado_por
    end

    def render
      Prawn::Document.new(page_size: "LETTER", page_layout: :landscape, margin: 30) do |pdf|
        @pdf = pdf
        @pdf.font "Helvetica"

        encabezado
        resumen_ejecutivo
        detalle_por_cuenta
        pie_de_pagina
      end.render
    end

    private

    def encabezado
      @pdf.fill_color COLOR_TITULO

      @pdf.text limpiar("DELEGACIÓN SINDICAL D-II-11"),
                size: 12,
                style: :bold,
                align: :center

      @pdf.text limpiar("INSTITUTO TECNOLÓGICO DE OAXACA"),
                size: 10,
                style: :bold,
                align: :center

      @pdf.move_down 8

      @pdf.text limpiar("CONCENTRADO FINANCIERO"),
                size: 16,
                style: :bold,
                align: :center

      @pdf.move_down 4

      @pdf.text limpiar("Resumen ejecutivo de ingresos y egresos"),
                size: 9,
                align: :center

      @pdf.move_down 8

      @pdf.stroke_color COLOR_LINEA
      @pdf.stroke_horizontal_rule
      @pdf.stroke_color "000000"

      @pdf.move_down 12
    end

    def resumen_ejecutivo
      @pdf.text limpiar("I. Datos generales del reporte"),
                size: 10,
                style: :bold,
                color: COLOR_SUBTITULO

      @pdf.move_down 6

      filas = [
        ["Tipo de reporte", nombre_tipo],
        ["Periodo consultado", periodo_texto],
        ["Cuenta financiera", cuenta_texto],
        ["Generado por", @generado_por&.nombre_usuario.to_s.presence || "Usuario"],
        ["Fecha de emisión", Time.current.strftime("%d/%m/%Y %H:%M")]
      ]

      dibujar_tabla_simple(
        filas: filas,
        columnas: [
          { label: "Campo", width: 160, align: :left },
          { label: "Valor", width: 520, align: :left }
        ],
        mostrar_encabezado: false
      )

      @pdf.move_down 12

      @pdf.text limpiar("II. Resumen ejecutivo"),
                size: 10,
                style: :bold,
                color: COLOR_SUBTITULO

      @pdf.move_down 6

      dibujar_resumen_financiero

      @pdf.move_down 10

      @pdf.text limpiar(
        "El presente concentrado muestra los movimientos financieros confirmados dentro del periodo seleccionado. " \
        "Cuando se visualizan todas las cuentas financieras, la información se presenta separada por cuenta para evitar mezclar ingresos, egresos y saldos."
      ),
                size: 8,
                leading: 2,
                align: :justify

      @pdf.move_down 14
    end

    def dibujar_resumen_financiero
      datos = [
        ["Ingresos confirmados", moneda(@total_ingresos)],
        ["Egresos confirmados", moneda(@total_egresos)],
        ["Saldo final", moneda(@saldo_final)]
      ]

      ancho_card = 220
      alto_card = 48
      espacio = 14
      x_inicial = @pdf.bounds.left
      y = @pdf.cursor

      datos.each_with_index do |(etiqueta, valor), index|
        x = x_inicial + (index * (ancho_card + espacio))

        @pdf.fill_color COLOR_FONDO_RESUMEN
        @pdf.fill_rectangle [x, y], ancho_card, alto_card

        @pdf.stroke_color COLOR_BORDE
        @pdf.stroke_rectangle [x, y], ancho_card, alto_card

        @pdf.fill_color COLOR_SUBTITULO
        @pdf.text_box limpiar(etiqueta),
                      at: [x + 10, y - 9],
                      width: ancho_card - 20,
                      height: 14,
                      size: 8,
                      style: :bold

        @pdf.fill_color "000000"
        @pdf.text_box limpiar(valor),
                      at: [x + 10, y - 26],
                      width: ancho_card - 20,
                      height: 18,
                      size: 13,
                      style: :bold
      end

      @pdf.fill_color "000000"
      @pdf.stroke_color "000000"
      @pdf.move_down alto_card + 4
    end

    def detalle_por_cuenta
      @pdf.text limpiar("III. Concentrado por cuenta financiera"),
                size: 10,
                style: :bold,
                color: COLOR_SUBTITULO

      @pdf.move_down 8

      if @bloques_cuentas.blank?
        @pdf.text limpiar("No hay información financiera para el periodo seleccionado."), size: 9
        return
      end

      @bloques_cuentas.each_with_index do |bloque, index|
        nueva_pagina_si_es_necesario(150) unless index.zero?

        seccion_cuenta(bloque)
      end
    end

    def seccion_cuenta(bloque)
      @pdf.move_down 6

      @pdf.text limpiar(bloque[:nombre_cuenta].to_s),
                size: 11,
                style: :bold

      @pdf.move_down 4

      filas_resumen = [
        ["Ingresos confirmados", moneda(bloque[:total_ingresos])],
        ["Egresos confirmados", moneda(bloque[:total_egresos])],
        ["Saldo financiero", moneda(bloque[:saldo_final])]
      ]

      dibujar_tabla_simple(
        filas: filas_resumen,
        columnas: [
          { label: "Indicador", width: 180, align: :left },
          { label: "Monto", width: 130, align: :right }
        ],
        mostrar_encabezado: false,
        ancho_total: 310
      )

      @pdf.move_down 8

      dibujar_ingresos(bloque) if mostrar_ingresos?
      dibujar_egresos(bloque) if mostrar_egresos?

      @pdf.move_down 12
    end

    def dibujar_ingresos(bloque)
      @pdf.text limpiar("Ingresos confirmados"),
                size: 9,
                style: :bold,
                color: COLOR_SUBTITULO

      @pdf.move_down 4

      ingresos = Array(bloque[:ingresos])

      if ingresos.blank?
        @pdf.text limpiar("No hay ingresos confirmados en este periodo."), size: 8
        @pdf.move_down 8
        return
      end

      columnas = [
        { label: "Fecha", width: 92, align: :center },
        { label: "Cooperación", width: 310, align: :left },
        { label: "Conceptos", width: 70, align: :center },
        { label: "Condonados", width: 75, align: :center },
        { label: "Total", width: 110, align: :right }
      ]

      filas = ingresos.map do |cooperacion|
        [
          fecha_hora(cooperacion.confirmada_at),
          cooperacion.nombre,
          cooperacion.cantidad_conceptos.to_s,
          cooperacion.cantidad_condonados.to_s,
          moneda(cooperacion.total_esperado)
        ]
      end

      dibujar_tabla_detalle(columnas: columnas, filas: filas)
      @pdf.move_down 8
    end

    def dibujar_egresos(bloque)
      @pdf.text limpiar("Egresos confirmados"),
                size: 9,
                style: :bold,
                color: COLOR_SUBTITULO

      @pdf.move_down 4

      egresos = Array(bloque[:egresos])

      if egresos.blank?
        @pdf.text limpiar("No hay egresos confirmados en este periodo."), size: 8
        @pdf.move_down 8
        return
      end

      columnas = [
        { label: "Folio", width: 80, align: :center },
        { label: "Fecha", width: 82, align: :center },
        { label: "Concepto", width: 360, align: :left },
        { label: "Monto", width: 110, align: :right },
        { label: "Estado", width: 70, align: :center }
      ]

      filas = egresos.map do |egreso|
        [
          egreso.folio_np,
          fecha(egreso.fecha_egreso),
          egreso.concepto,
          moneda(egreso.monto),
          egreso.estado.to_s.humanize
        ]
      end

      dibujar_tabla_detalle(columnas: columnas, filas: filas)
      @pdf.move_down 8
    end

    def dibujar_tabla_simple(filas:, columnas:, mostrar_encabezado: true, ancho_total: nil)
      ancho_total ||= columnas.sum { |columna| columna[:width] }

      dibujar_encabezado_tabla(columnas, ancho_total) if mostrar_encabezado

      filas.each do |fila|
        nueva_pagina_si_es_necesario(24)
        dibujar_fila_tabla(columnas, fila, 22, false, ancho_total)
      end
    end

    def dibujar_tabla_detalle(columnas:, filas:)
      ancho_total = columnas.sum { |columna| columna[:width] }

      dibujar_encabezado_tabla(columnas, ancho_total)

      filas.each do |fila|
        nueva_pagina_si_es_necesario(28)
        dibujar_fila_tabla(columnas, fila, 26, false, ancho_total)
      end
    end

    def dibujar_encabezado_tabla(columnas, ancho_total)
      nueva_pagina_si_es_necesario(30)

      altura = 22
      x = @pdf.bounds.left
      y = @pdf.cursor

      @pdf.fill_color COLOR_ENCABEZADO_TABLA
      @pdf.fill_rectangle [x, y], ancho_total, altura

      @pdf.stroke_color COLOR_BORDE
      @pdf.stroke_rectangle [x, y], ancho_total, altura

      @pdf.fill_color "000000"

      x_actual = x

      columnas.each do |columna|
        @pdf.text_box limpiar(columna[:label]),
                      at: [x_actual + 4, y - 6],
                      width: columna[:width] - 8,
                      height: altura,
                      size: 7.5,
                      style: :bold,
                      align: columna[:align]

        x_actual += columna[:width]
      end

      @pdf.move_down altura
      @pdf.fill_color "000000"
      @pdf.stroke_color "000000"
    end

    def dibujar_fila_tabla(columnas, fila, altura, encabezado, ancho_total)
      x = @pdf.bounds.left
      y = @pdf.cursor

      @pdf.fill_color "FFFFFF"
      @pdf.fill_rectangle [x, y], ancho_total, altura

      @pdf.stroke_color COLOR_BORDE
      @pdf.stroke_rectangle [x, y], ancho_total, altura

      @pdf.fill_color "000000"

      x_actual = x

      columnas.each_with_index do |columna, index|
        valor = fila[index].to_s

        @pdf.text_box limpiar(valor),
                      at: [x_actual + 4, y - 7],
                      width: columna[:width] - 8,
                      height: altura - 4,
                      size: encabezado ? 7.5 : 7,
                      style: encabezado ? :bold : :normal,
                      align: columna[:align],
                      overflow: :shrink_to_fit,
                      min_font_size: 5

        x_actual += columna[:width]
      end

      @pdf.move_down altura
      @pdf.fill_color "000000"
      @pdf.stroke_color "000000"
    end

    def nueva_pagina_si_es_necesario(altura_necesaria)
      return unless @pdf.cursor < altura_necesaria + 45

      @pdf.start_new_page
      encabezado_continuacion
    end

    def encabezado_continuacion
      @pdf.text limpiar("CONCENTRADO FINANCIERO"),
                size: 11,
                style: :bold,
                align: :center

      @pdf.text limpiar("Continuación"),
                size: 8,
                align: :center

      @pdf.move_down 10
    end

    def pie_de_pagina
      total_paginas = @pdf.page_count

      (1..total_paginas).each do |numero_pagina|
        @pdf.go_to_page(numero_pagina)

        @pdf.fill_color "000000"
        @pdf.stroke_color COLOR_LINEA

        @pdf.bounding_box([@pdf.bounds.left, 20], width: @pdf.bounds.width, height: 16) do
          @pdf.stroke_horizontal_rule
          @pdf.move_down 3

          @pdf.text limpiar("Sistema de Gestión Sindical · Concentrado financiero"),
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

    def mostrar_ingresos?
      @tipo.in?(%w[general ingresos])
    end

    def mostrar_egresos?
      @tipo.in?(%w[general egresos])
    end

    def nombre_tipo
      case @tipo
      when "ingresos"
        "Solo ingresos"
      when "egresos"
        "Solo egresos"
      else
        "General: ingresos y egresos"
      end
    end

    def periodo_texto
      inicio = @fecha_inicio&.strftime("%d/%m/%Y") || "inicio"
      fin = @fecha_fin&.strftime("%d/%m/%Y") || "actualidad"

      "#{inicio} - #{fin}"
    end

    def cuenta_texto
      @cuenta_financiera_actual&.nombre || "Todas las cuentas financieras"
    end

    def moneda(valor)
      format("$%.2f", valor.to_d)
    end

    def fecha(valor)
      valor.present? ? valor.strftime("%d/%m/%Y") : "-"
    end

    def fecha_hora(valor)
      valor.present? ? valor.strftime("%d/%m/%Y %H:%M") : "-"
    end

    def limpiar(texto)
      texto.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?")
    end
  end
end
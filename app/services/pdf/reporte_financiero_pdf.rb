require "prawn"

module Pdf
  class ReporteFinancieroPdf
    LOGO_SECCION_22 = Rails.root.join("app/assets/images/LogoSeccion22.png").to_s

    RESPONSABLE_ADMIN = "Esteban López Vázquez".freeze
    PUESTO_ADMIN = "Secretario General".freeze

    RESPONSABLE_DEFAULT = "RESPONSABLE NO ASIGNADO".freeze
    PUESTO_DEFAULT = "PUESTO NO ASIGNADO".freeze

    SEPARACION_COLUMNAS = 14

    ALTO_BLOQUE_SUPERIOR = 150
    ALTO_TITULO_TABLA = 20
    ALTO_ENCABEZADO_TABLA = 18
    ALTO_FILA = 28

    MAX_FILAS_POR_PAGINA = 11

    MESES = {
      1 => "enero",
      2 => "febrero",
      3 => "marzo",
      4 => "abril",
      5 => "mayo",
      6 => "junio",
      7 => "julio",
      8 => "agosto",
      9 => "septiembre",
      10 => "octubre",
      11 => "noviembre",
      12 => "diciembre"
    }.freeze

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
      Prawn::Document.new(page_size: "LETTER", page_layout: :portrait, margin: 24) do |pdf|
        @pdf = pdf
        @pdf.font "Helvetica"

        bloques_para_render.each_with_index do |bloque, index|
          @pdf.start_new_page unless index.zero?
          dibujar_cuenta_financiera(bloque)
        end

        pie_de_pagina
      end.render
    end

    private

    def bloques_para_render
      return @bloques_cuentas if @bloques_cuentas.present?

      [
        {
          cuenta: @cuenta_financiera_actual,
          nombre_cuenta: cuenta_texto,
          ingresos: [],
          egresos: [],
          total_ingresos: @total_ingresos,
          total_egresos: @total_egresos,
          saldo_final: @saldo_final
        }
      ]
    end

    def dibujar_cuenta_financiera(bloque)
      ingresos = mostrar_ingresos? ? filas_ingresos(bloque) : []
      egresos = mostrar_egresos? ? filas_egresos(bloque) : []

      total_filas = [
        mostrar_ingresos? ? ingresos.size : 1,
        mostrar_egresos? ? egresos.size : 1,
        1
      ].max

      paginas_necesarias = (total_filas.to_f / MAX_FILAS_POR_PAGINA).ceil
      paginas_necesarias = 1 if paginas_necesarias.zero?

      paginas_necesarias.times do |pagina|
        @pdf.start_new_page if pagina.positive?

        offset = pagina * MAX_FILAS_POR_PAGINA

        ingresos_pagina = ingresos.slice(offset, MAX_FILAS_POR_PAGINA) || []
        egresos_pagina = egresos.slice(offset, MAX_FILAS_POR_PAGINA) || []

        ultima_pagina = pagina == paginas_necesarias - 1

        encabezado_principal(
          bloque,
          pagina: pagina + 1,
          total_paginas_cuenta: paginas_necesarias
        )

        bloque_superior(bloque)

        tablas_financieras(
          ingresos: ingresos_pagina,
          egresos: egresos_pagina,
          ingresos_vacios: ingresos.blank?,
          egresos_vacios: egresos.blank?,
          offset: offset
        )

        if ultima_pagina
          totales_finales(bloque)
          firma_responsable(bloque)
          lugar_y_fecha
        else
          texto_continuacion
        end
      end
    end

    def encabezado_principal(bloque, pagina:, total_paginas_cuenta:)
      @pdf.text limpiar("SECCIÓN 22 - SISTEMA DE GESTIÓN SINDICAL"),
                size: 12,
                style: :bold,
                align: :center

      @pdf.move_down 7

      @pdf.text limpiar(nombre_cuenta(bloque).upcase),
                size: 12,
                style: :bold,
                align: :center

      @pdf.text limpiar("CONCENTRADO FINANCIERO"),
                size: 11,
                style: :bold,
                align: :center

      if total_paginas_cuenta > 1
        @pdf.move_down 3
        @pdf.text limpiar("Página #{pagina} de #{total_paginas_cuenta} de esta cuenta"),
                  size: 9,
                  align: :center
      end

      @pdf.move_down 10
    end

    def bloque_superior(bloque)
      ancho_total = @pdf.bounds.width
      ancho_logo = 238
      ancho_resumen = ancho_total - ancho_logo - SEPARACION_COLUMNAS

      y = @pdf.cursor

      dibujar_logo(
        x: 0,
        y: y,
        width: ancho_logo,
        height: ALTO_BLOQUE_SUPERIOR
      )

      dibujar_resumen(
        bloque: bloque,
        x: ancho_logo + SEPARACION_COLUMNAS,
        y: y,
        width: ancho_resumen,
        height: ALTO_BLOQUE_SUPERIOR
      )

      @pdf.move_cursor_to(y - ALTO_BLOQUE_SUPERIOR - 14)
    end

    def dibujar_logo(x:, y:, width:, height:)
      if File.exist?(LOGO_SECCION_22)
        @pdf.bounding_box([x, y], width: width, height: height) do
          @pdf.move_down 14

          @pdf.image LOGO_SECCION_22,
                     fit: [width - 76, height - 38],
                     position: :center,
                     vposition: :center
        end
      else
        @pdf.text_box limpiar("Logo Sección 22"),
                      at: [x + 10, y - 55],
                      width: width - 20,
                      height: 30,
                      size: 12,
                      style: :bold,
                      align: :center
      end
    rescue StandardError
      @pdf.text_box limpiar("Logo Sección 22"),
                    at: [x + 10, y - 55],
                    width: width - 20,
                    height: 30,
                    size: 12,
                    style: :bold,
                    align: :center
    end

    def dibujar_resumen(bloque:, x:, y:, width:, height:)

      @pdf.text_box limpiar("RESUMEN"),
                    at: [x + 8, y - 10],
                    width: width - 16,
                    height: 18,
                    size: 15,
                    style: :bold,
                    align: :center

      margen_x = x + 10
      ancho_contenido = width - 20

      y_base = y - 40
      alto_linea = 40

      dibujar_linea_resumen(
        x: margen_x,
        y: y_base,
        width: ancho_contenido,
        etiqueta: "TOTAL DE INGRESOS #{periodo_resumen}",
        valor: mostrar_ingresos? ? moneda(bloque[:total_ingresos]) : "NO INCLUIDO"
      )

      dibujar_linea_resumen(
        x: margen_x,
        y: y_base - alto_linea,
        width: ancho_contenido,
        etiqueta: "TOTAL DE EGRESOS #{periodo_resumen}",
        valor: mostrar_egresos? ? moneda(bloque[:total_egresos]) : "NO INCLUIDO"
      )

      dibujar_linea_resumen(
        x: margen_x,
        y: y_base - (alto_linea * 2),
        width: ancho_contenido,
        etiqueta: "SALDO",
        valor: mostrar_ingresos? && mostrar_egresos? ? moneda(bloque[:saldo_final]) : "NO APLICA"
      )
    end

    def dibujar_linea_resumen(x:, y:, width:, etiqueta:, valor:)
      @pdf.text_box limpiar(etiqueta),
                    at: [x, y],
                    width: width,
                    height: 9,
                    size: 8.2,
                    style: :bold,
                    overflow: :shrink_to_fit,
                    min_font_size: 7

      @pdf.stroke_line [x, y - 11], [x + width, y - 11]

      @pdf.text_box limpiar(valor),
                    at: [x, y - 15],
                    width: width,
                    height: 13,
                    size: 13,
                    style: :bold,
                    overflow: :shrink_to_fit,
                    min_font_size: 10
    end

    def tablas_financieras(ingresos:, egresos:, ingresos_vacios:, egresos_vacios:, offset:)
  ancho_columna = (@pdf.bounds.width - SEPARACION_COLUMNAS) / 2.0
  y = @pdf.cursor

  # Línea continua superior para separar el bloque de arriba
  linea_horizontal(x: 0, y: y, width: @pdf.bounds.width)

  y_contenido = y - 6

  altura_ingresos = dibujar_tabla_columna(
    titulo: "INGRESOS",
    filas: ingresos,
    x: 0,
    y: y_contenido,
    width: ancho_columna,
    mensaje_vacio: mensaje_ingresos_vacio(ingresos_vacios),
    offset: offset,
    dibujar_linea_superior: false
  )

  altura_egresos = dibujar_tabla_columna(
    titulo: "GASTOS",
    filas: egresos,
    x: ancho_columna + SEPARACION_COLUMNAS,
    y: y_contenido,
    width: ancho_columna,
    mensaje_vacio: mensaje_egresos_vacio(egresos_vacios),
    offset: offset,
    dibujar_linea_superior: false
  )

  altura_usada = [altura_ingresos, altura_egresos].max

  @pdf.move_cursor_to(y_contenido - altura_usada - 12)
end

    def dibujar_tabla_columna(titulo:, filas:, x:, y:, width:, mensaje_vacio:, offset:, dibujar_linea_superior: true)
  altura_total = ALTO_TITULO_TABLA + ALTO_ENCABEZADO_TABLA

  linea_horizontal(x: x, y: y, width: width) if dibujar_linea_superior
  linea_horizontal(x: x, y: y - ALTO_TITULO_TABLA, width: width)

  @pdf.text_box limpiar(titulo),
                at: [x + 6, y - 6],
                width: width - 12,
                height: ALTO_TITULO_TABLA,
                size: 11,
                style: :bold

  y_actual = y - ALTO_TITULO_TABLA

  linea_horizontal(x: x, y: y_actual - ALTO_ENCABEZADO_TABLA, width: width)

  columnas = columnas_para(width)
  x_columna = x

  columnas.each do |columna|
    @pdf.text_box limpiar(columna[:label]),
                  at: [x_columna + 3, y_actual - 6],
                  width: columna[:width] - 6,
                  height: ALTO_ENCABEZADO_TABLA,
                  size: 7.7,
                  style: :bold,
                  align: columna[:align],
                  overflow: :shrink_to_fit,
                  min_font_size: 6.8

    x_columna += columna[:width]
  end

  y_actual -= ALTO_ENCABEZADO_TABLA

  if mensaje_vacio.present?
    @pdf.text_box limpiar(mensaje_vacio),
                  at: [x + 6, y_actual - 8],
                  width: width - 12,
                  height: ALTO_FILA - 4,
                  size: 8.5,
                  style: :bold

    linea_horizontal(x: x, y: y_actual - ALTO_FILA, width: width)

    return altura_total + ALTO_FILA
  end

  filas.each_with_index do |fila, index|
    dibujar_fila_financiera(
      fila: fila,
      columnas: columnas,
      x: x,
      y: y_actual,
      width: width,
      numero: offset + index + 1
    )

    y_actual -= ALTO_FILA
    altura_total += ALTO_FILA
  end

  altura_total
end

    def dibujar_fila_financiera(fila:, columnas:, x:, y:, width:, numero:)
      valores = {
        concepto: "#{numero}. #{fila[:concepto]}",
        recibo: fila[:recibo],
        cantidad: fila[:cantidad]
      }

      x_actual = x

      columnas.each do |columna|
        @pdf.text_box limpiar(valores[columna[:key]].to_s),
                      at: [x_actual + 3, y - 6],
                      width: columna[:width] - 6,
                      height: ALTO_FILA - 4,
                      size: 7.7,
                      align: columna[:align],
                      overflow: :shrink_to_fit,
                      min_font_size: 6.5

        x_actual += columna[:width]
      end

      linea_horizontal(x: x, y: y - ALTO_FILA, width: width)
    end

    def columnas_para(width)
      concepto_width = (width * 0.50).round(2)
      recibo_width = (width * 0.25).round(2)
      cantidad_width = (width - concepto_width - recibo_width).round(2)

      [
        {
          key: :concepto,
          label: "CONCEPTO",
          width: concepto_width,
          align: :left
        },
        {
          key: :recibo,
          label: "RECIBO No.",
          width: recibo_width,
          align: :center
        },
        {
          key: :cantidad,
          label: "CANTIDAD",
          width: cantidad_width,
          align: :right
        }
      ]
    end

    def totales_finales(bloque)
      ancho_columna = (@pdf.bounds.width - SEPARACION_COLUMNAS) / 2.0
      y = @pdf.cursor

      if mostrar_ingresos?
        dibujar_total_columna(
          x: 0,
          y: y,
          width: ancho_columna,
          etiqueta: "TOTAL DE INGRESOS",
          valor: moneda(bloque[:total_ingresos])
        )
      end

      if mostrar_egresos?
        dibujar_total_columna(
          x: ancho_columna + SEPARACION_COLUMNAS,
          y: y,
          width: ancho_columna,
          etiqueta: "TOTAL DE GASTOS",
          valor: moneda(bloque[:total_egresos])
        )
      end

      @pdf.move_cursor_to(y - 30)
    end

    def dibujar_total_columna(x:, y:, width:, etiqueta:, valor:)
      linea_horizontal(x: x, y: y, width: width)
      linea_horizontal(x: x, y: y - 20, width: width)

      @pdf.text_box limpiar(etiqueta),
                    at: [x + 6, y - 6],
                    width: width * 0.55,
                    height: 18,
                    size: 9,
                    style: :bold

      @pdf.text_box limpiar(valor),
                    at: [x + (width * 0.55), y - 6],
                    width: width * 0.42,
                    height: 18,
                    size: 9,
                    style: :bold,
                    align: :right,
                    overflow: :shrink_to_fit,
                    min_font_size: 7.5
    end

    def firma_responsable(bloque)
      nombre = responsable_documento(bloque[:cuenta])
      puesto = puesto_documento(bloque[:cuenta])

      y = 112

      @pdf.text_box limpiar("Responsable:"),
                    at: [0, y],
                    width: 88,
                    height: 14,
                    size: 10,
                    style: :bold

      @pdf.text_box limpiar(nombre),
                    at: [92, y],
                    width: 260,
                    height: 14,
                    size: 10,
                    style: :bold

      @pdf.text_box limpiar(puesto),
                    at: [92, y - 15],
                    width: 260,
                    height: 14,
                    size: 10,
                    style: :italic
    end

    def lugar_y_fecha
      @pdf.text_box limpiar("Oaxaca de Juárez, Oaxaca, #{fecha_larga(Date.current)}."),
                    at: [0, 48],
                    width: @pdf.bounds.width,
                    height: 14,
                    size: 9.5,
                    style: :italic
    end

    def texto_continuacion
      @pdf.move_down 10

      @pdf.text limpiar("Continúa en la siguiente página."),
                size: 10,
                style: :bold,
                align: :right
    end

    def filas_ingresos(bloque)
      Array(bloque[:ingresos]).map do |cooperacion|
        {
          concepto: cooperacion.nombre.to_s,
          recibo: recibo_cooperacion(cooperacion),
          cantidad: moneda(cooperacion.total_esperado)
        }
      end
    end

    def filas_egresos(bloque)
      Array(bloque[:egresos]).map do |egreso|
        {
          concepto: egreso.concepto.to_s,
          recibo: egreso.folio_np.to_s.presence || "-",
          cantidad: moneda(egreso.monto)
        }
      end
    end

    def recibo_cooperacion(cooperacion)
      if cooperacion.respond_to?(:folio) && cooperacion.folio.present?
        cooperacion.folio.to_s
      else
        "COOP-#{format('%04d', cooperacion.id.to_i)}"
      end
    end

    def mensaje_ingresos_vacio(ingresos_vacios)
      return "Ingresos no incluidos en este reporte." unless mostrar_ingresos?
      return "No hay ingresos confirmados en el periodo." if ingresos_vacios

      nil
    end

    def mensaje_egresos_vacio(egresos_vacios)
      return "Egresos no incluidos en este reporte." unless mostrar_egresos?
      return "No hay egresos confirmados en el periodo." if egresos_vacios

      nil
    end

    def responsable_documento(cuenta)
      return RESPONSABLE_ADMIN if @generado_por&.admin?

      if cuenta.respond_to?(:responsable_para_documento)
        cuenta.responsable_para_documento
      else
        cuenta&.responsable_nombre.to_s.presence || RESPONSABLE_DEFAULT
      end
    end

    def puesto_documento(cuenta)
      return PUESTO_ADMIN if @generado_por&.admin?

      if cuenta.respond_to?(:puesto_para_documento)
        cuenta.puesto_para_documento
      else
        cuenta&.responsable_puesto.to_s.presence || PUESTO_DEFAULT
      end
    end

    def mostrar_ingresos?
      @tipo.in?(%w[general ingresos])
    end

    def mostrar_egresos?
      @tipo.in?(%w[general egresos])
    end

    def periodo_texto
      inicio = @fecha_inicio&.strftime("%d/%m/%Y") || "INICIO"
      fin = @fecha_fin&.strftime("%d/%m/%Y") || "ACTUALIDAD"

      "#{inicio} - #{fin}"
    end

    def periodo_resumen
      "DEL #{periodo_texto}"
    end

    def cuenta_texto
      @cuenta_financiera_actual&.nombre || "Todas las cuentas financieras"
    end

    def nombre_cuenta(bloque)
      bloque[:nombre_cuenta].presence ||
        bloque[:cuenta]&.nombre.to_s.presence ||
        cuenta_texto
    end

    def moneda(valor)
      numero = valor.to_d
      signo = numero.negative? ? "-" : ""
      numero_absoluto = numero.abs

      entero, decimal = format("%.2f", numero_absoluto).split(".")
      entero_con_comas = entero.reverse.scan(/\d{1,3}/).join(",").reverse

      "$#{signo}#{entero_con_comas}.#{decimal}"
    end

    def fecha_larga(fecha)
      "#{fecha.day} de #{MESES[fecha.month]} de #{fecha.year}"
    end

    def linea_horizontal(x:, y:, width:)
      @pdf.stroke_line [x, y], [x + width, y]
    end

    def pie_de_pagina
      total_paginas = @pdf.page_count

      (1..total_paginas).each do |numero_pagina|
        @pdf.go_to_page(numero_pagina)

        @pdf.bounding_box([0, 18], width: @pdf.bounds.width, height: 14) do
          @pdf.stroke_horizontal_rule
          @pdf.move_down 2

          @pdf.text_box limpiar("Sistema de Gestión Sindical · Reporte financiero"),
                        at: [0, 10],
                        width: 260,
                        height: 10,
                        size: 8

          @pdf.text_box limpiar("Página #{numero_pagina} de #{total_paginas}"),
                        at: [@pdf.bounds.width - 120, 10],
                        width: 120,
                        height: 10,
                        size: 8,
                        align: :right
        end
      end

      @pdf.go_to_page(total_paginas)
    end

    def limpiar(texto)
      texto.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?")
    end
  end
end
require "prawn"

module Pdf
  class CooperacionRecibosPdf
    LOGO_IZQUIERDO = Rails.root.join("app/assets/images/LogoSeccion22.png").to_s
    LOGO_DERECHO = Rails.root.join("app/assets/images/LogoITO.png").to_s
    ARIAL_FONT = Rails.root.join("app/assets/fonts/arial.ttf").to_s

    MESES = {
      1 => "ENERO",
      2 => "FEBRERO",
      3 => "MARZO",
      4 => "ABRIL",
      5 => "MAYO",
      6 => "JUNIO",
      7 => "JULIO",
      8 => "AGOSTO",
      9 => "SEPTIEMBRE",
      10 => "OCTUBRE",
      11 => "NOVIEMBRE",
      12 => "DICIEMBRE"
    }.freeze

    def initialize(cooperacion)
      @cooperacion = cooperacion
      @desglose = cooperacion.desglose_por_trabajador
    end

    def render
      Prawn::Document.new(page_size: "LETTER", margin: 0) do |pdf|
        @pdf = pdf
        configurar_fuente

        if @desglose.blank?
          texto("No hay trabajadores para generar recibos.", x: 50, y: 720, width: 500, size: 10)
        else
          @desglose.each_with_index do |fila_original, index|
            @pdf.start_new_page unless index.zero?

            fila = normalizar_fila(fila_original)
            folio = index + 1

            # Recibo superior
            dibujar_recibo(fila, folio, top_y: 740)

            # Recibo inferior
            dibujar_recibo(fila, folio, top_y: 375)
          end
        end
      end.render
    end

    private

    def configurar_fuente
      if File.exist?(ARIAL_FONT)
        @pdf.font_families.update(
          "Arial" => {
            normal: ARIAL_FONT,
            bold: ARIAL_FONT
          }
        )

        @pdf.font "Arial"
      else
        @pdf.font "Helvetica"
      end
    end

    def dibujar_recibo(fila, folio, top_y:)
      dibujar_logos(top_y)
      dibujar_encabezado(top_y)
      dibujar_folio(folio, top_y)
      dibujar_datos_principales(fila, top_y)
      dibujar_conceptos(fila, top_y)
      dibujar_total(fila, top_y)
      dibujar_fecha(top_y)
      dibujar_firma(top_y)
    end

    def dibujar_logos(top_y)
      if File.exist?(LOGO_IZQUIERDO)
        @pdf.image LOGO_IZQUIERDO,
                   at: [68, top_y - 2],
                   width: 42
      end

      if File.exist?(LOGO_DERECHO)
        @pdf.image LOGO_DERECHO,
                   at: [505, top_y - 2],
                   width: 42
      end
    rescue StandardError
      nil
    end

    def dibujar_encabezado(top_y)
      texto(
        "DELEGACIÓN SINDICAL D-II-11",
        x: 180,
        y: top_y - 6,
        width: 255,
        size: 9,
        style: :bold,
        align: :center
      )

      texto(
        "INSTITUTO TECNOLÓGICO DE OAXACA",
        x: 180,
        y: top_y - 20,
        width: 255,
        size: 9,
        style: :bold,
        align: :center
      )
    end

    def dibujar_folio(folio, top_y)
      texto(
        "FOLIO: #{folio}",
        x: 490,
        y: top_y - 58,
        width: 90,
        size: 10,
        style: :bold
      )
    end

    def dibujar_datos_principales(fila, top_y)
      texto(
        "RECIBÍ DE: #{nombre_trabajador(fila).upcase}",
        x: 55,
        y: top_y - 58,
        width: 410,
        size: 9
      )

      texto(
        "LA CANTIDAD DE: #{cantidad_en_formato_recibo(fila[:total])}",
        x: 55,
        y: top_y - 88,
        width: 430,
        size: 9
      )

      texto(
        "POR CONCEPTO DE:",
        x: 55,
        y: top_y - 122,
        width: 200,
        size: 9
      )
    end

    def dibujar_conceptos(fila, top_y)
      conceptos = conceptos_para_recibo(fila)

      y_actual = top_y - 151

      conceptos.first(5).each do |concepto|
        nombre = concepto[:nombre].to_s.upcase
        importe = concepto[:importe]

        texto(
          nombre,
          x: 55,
          y: y_actual,
          width: 335,
          size: 8.8
        )

        if importe.present?
          texto(
            moneda(importe),
            x: 392,
            y: y_actual,
            width: 80,
            size: 8.8,
            align: :right
          )
        end

        y_actual -= 12
      end

      return unless fila[:condonado]

      texto(
        "TRABAJADOR CONDONADO EN ESTA COOPERACIÓN",
        x: 55,
        y: top_y - 208,
        width: 390,
        size: 9,
        style: :bold
      )
    end

    def dibujar_total(fila, top_y)
      texto(
        "TOTAL A PAGAR",
        x: 55,
        y: top_y - 235,
        width: 180,
        size: 11,
        style: :bold
      )

      texto(
        moneda(fila[:total]),
        x: 390,
        y: top_y - 235,
        width: 85,
        size: 11,
        style: :bold,
        align: :right
      )
    end

    def dibujar_fecha(top_y)
      texto(
        fecha_actual_recibo,
        x: 340,
        y: top_y - 270,
        width: 220,
        size: 8,
        align: :left
      )
    end

    def dibujar_firma(top_y)
      texto(
        "RECIBÍ CUOTA",
        x: 55,
        y: top_y - 298,
        width: 130,
        size: 9
      )

      linea(x1: 55, x2: 245, y: top_y - 330)

      texto(
        "C. MARÍA TELMA RUIZ REYES",
        x: 55,
        y: top_y - 340,
        width: 230,
        size: 8.5,
        style: :bold
      )

      texto(
        "SECRETARIA DE FINANZAS",
        x: 55,
        y: top_y - 352,
        width: 230,
        size: 8.5
      )
    end

    def texto(contenido, x:, y:, width:, size:, style: nil, align: :left)
      @pdf.text_box(
        limpiar(contenido.to_s),
        at: [x, y],
        width: width,
        height: 28,
        size: size,
        style: style,
        align: align,
        overflow: :shrink_to_fit,
        min_font_size: 6
      )
    end

    def linea(x1:, x2:, y:)
      @pdf.stroke do
        @pdf.line_width = 0.8
        @pdf.stroke_line [x1, y], [x2, y]
      end
    end

    def normalizar_fila(fila_original)
      fila_original.respond_to?(:with_indifferent_access) ? fila_original.with_indifferent_access : {}
    end

    def nombre_trabajador(fila)
      trabajador = fila[:trabajador]

      fila[:nombre_trabajador].presence ||
        fila[:nombre].presence ||
        trabajador&.nombre_completo ||
        "Trabajador sin nombre"
    end

    def conceptos_para_recibo(fila)
      if fila[:condonado]
        return [
          {
            nombre: "CONDONACIÓN DE CUOTA - #{@cooperacion.nombre}",
            importe: 0.to_d
          },
          {
            nombre: "NO SE REALIZA COBRO AL TRABAJADOR",
            importe: nil
          }
        ]
      end

      conceptos = fila[:conceptos].presence || fila[:detalle_conceptos].presence || []

      Array(conceptos).map do |concepto_original|
        concepto = concepto_original.respond_to?(:with_indifferent_access) ? concepto_original.with_indifferent_access : {}

        {
          nombre: concepto[:nombre].presence || "Concepto",
          importe: concepto[:importe].to_d
        }
      end
    end

    def moneda(valor)
      format("$ %.2f", valor.to_d)
    end

    def cantidad_en_formato_recibo(valor)
      monto = valor.to_d
      pesos = monto.floor
      centavos = ((monto - pesos) * 100).round

      "#{moneda(monto)} PESOS #{format('%02d', centavos)}/100 M.N."
    end

    def fecha_actual_recibo
      fecha = Date.current

      "OAXACA DE JUÁREZ, OAX., #{MESES[fecha.month]} DE #{fecha.year}"
    end

    def limpiar(texto)
      texto.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?")
    end
  end
end
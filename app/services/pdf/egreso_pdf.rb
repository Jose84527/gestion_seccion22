require "prawn"

module Pdf
  class EgresoPdf
    MESES = {
      1 => "Enero",
      2 => "Febrero",
      3 => "Marzo",
      4 => "Abril",
      5 => "Mayo",
      6 => "Junio",
      7 => "Julio",
      8 => "Agosto",
      9 => "Septiembre",
      10 => "Octubre",
      11 => "Noviembre",
      12 => "Diciembre"
    }.freeze

    RESPONSABLE_DEFAULT = "RESPONSABLE NO ASIGNADO".freeze
    PUESTO_DEFAULT = "PUESTO NO ASIGNADO".freeze
    CUENTA_DEFAULT = "SECRETARÍA DE FINANZAS".freeze

    def initialize(egreso)
      @egreso = egreso
      @cuenta_financiera = egreso.cuenta_financiera
    end

    def render
      Prawn::Document.new(page_size: "LETTER", margin: 0) do |pdf|
        @pdf = pdf
        @pdf.font "Helvetica"

        encabezado
        datos_principales
        firmas_fijas
        firma_recibi
      end.render
    end

    private

    def encabezado
      texto_centrado(
        "COMITÉ EJECUTIVO DELEGACIONAL D-II-11",
        y: 675,
        size: 16,
        style: :bold
      )

      texto_centrado(
        nombre_cuenta_documento.upcase,
        y: 640,
        size: 16,
        style: :bold
      )

      @pdf.text_box(
        folio_np,
        at: [430, 595],
        width: 120,
        height: 20,
        size: 12,
        style: :bold,
        align: :left
      )
    end

    def datos_principales
      @pdf.text_box(
        "Recibí la cantidad de: #{monto_formateado}",
        at: [85, 550],
        width: 470,
        height: 35,
        size: 12
      )

      @pdf.text_box(
        "Por concepto de: #{@egreso.concepto}",
        at: [85, 495],
        width: 470,
        height: 55,
        size: 12
      )

      @pdf.text_box(
        "Que se llevó a cabo el día #{dia_egreso} de #{mes_egreso} de #{anio_egreso}",
        at: [85, 390],
        width: 470,
        height: 35,
        size: 12
      )
    end

    def firmas_fijas
      @pdf.text_box(
        "Autorizó",
        at: [150, 315],
        width: 120,
        height: 20,
        size: 12,
        align: :center
      )

      @pdf.text_box(
        "Vo. Bo.",
        at: [370, 315],
        width: 120,
        height: 20,
        size: 12,
        align: :center
      )

      linea(x1: 105, x2: 285, y: 225)
      linea(x1: 330, x2: 510, y: 225)

      @pdf.text_box(
        "Esteban López Vázquez",
        at: [105, 212],
        width: 180,
        height: 18,
        size: 10,
        style: :bold,
        align: :center
      )

      @pdf.text_box(
        "Secretario General",
        at: [105, 196],
        width: 180,
        height: 18,
        size: 10,
        align: :center
      )

      @pdf.text_box(
        responsable_documento,
        at: [330, 212],
        width: 180,
        height: 18,
        size: 10,
        style: :bold,
        align: :center,
        overflow: :shrink_to_fit,
        min_font_size: 7
      )

      @pdf.text_box(
        puesto_documento,
        at: [330, 196],
        width: 180,
        height: 18,
        size: 10,
        align: :center,
        overflow: :shrink_to_fit,
        min_font_size: 7
      )
    end

    def firma_recibi
      texto_centrado(
        "Recibí",
        y: 135,
        size: 12
      )

      linea(x1: 205, x2: 405, y: 55)

      texto_centrado(
        "Nombre, fecha y firma",
        y: 38,
        size: 10,
        style: :bold
      )
    end

    def texto_centrado(texto, y:, size:, style: nil)
      @pdf.text_box(
        limpiar(texto),
        at: [0, y],
        width: 612,
        height: 30,
        size: size,
        style: style,
        align: :center
      )
    end

    def linea(x1:, x2:, y:)
      @pdf.stroke do
        @pdf.line_width = 1
        @pdf.stroke_line [x1, y], [x2, y]
      end
    end

    def folio_np
      texto = @egreso.folio_np.to_s

      if texto.start_with?("N.P.")
        texto
      else
        "N.P. #{texto}"
      end
    end

    def monto_formateado
      format("$%.2f", @egreso.monto.to_d)
    end

    def dia_egreso
      return "__" if @egreso.fecha_egreso.blank?

      @egreso.fecha_egreso.day
    end

    def mes_egreso
      return "__________" if @egreso.fecha_egreso.blank?

      MESES[@egreso.fecha_egreso.month]
    end

    def anio_egreso
      return "____" if @egreso.fecha_egreso.blank?

      @egreso.fecha_egreso.year
    end

    def nombre_cuenta_documento
      @cuenta_financiera&.nombre.to_s.presence || CUENTA_DEFAULT
    end

    def responsable_documento
      if @cuenta_financiera.respond_to?(:responsable_para_documento)
        @cuenta_financiera.responsable_para_documento
      else
        @cuenta_financiera&.responsable_nombre.to_s.presence || RESPONSABLE_DEFAULT
      end
    end

    def puesto_documento
      if @cuenta_financiera.respond_to?(:puesto_para_documento)
        @cuenta_financiera.puesto_para_documento
      else
        @cuenta_financiera&.responsable_puesto.to_s.presence || PUESTO_DEFAULT
      end
    end

    def limpiar(texto)
      texto.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?")
    end
  end
end
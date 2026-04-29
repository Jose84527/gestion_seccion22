require "prawn"
require "prawn/table"

module Pdf
  class CooperacionListaGeneralPdf
    def initialize(cooperacion)
      @cooperacion = cooperacion
      @desglose = cooperacion.desglose_por_trabajador
    end

    def render
      Prawn::Document.new(
        page_size: "LETTER",
        page_layout: :landscape,
        margin: [45, 50, 45, 50]
      ) do |pdf|
        @pdf = pdf

        construir_encabezado
        pdf.move_down 18
        construir_tabla
        pdf.move_down 30
        construir_total
      end.render
    end

    private

    def construir_encabezado
      @pdf.text "Lista de trabajadores para la cooperación #{@cooperacion.nombre}",
                size: 13,
                style: :bold,
                align: :left

      @pdf.move_down 14

      @pdf.text "Fecha de inicio: #{formatear_fecha(@cooperacion.fecha_inicio_vigencia)}",
                size: 11

      @pdf.move_down 8

      @pdf.text "Fecha de finalización: #{formatear_fecha(@cooperacion.fecha_fin_vigencia)}",
                size: 11
    end

    def construir_tabla
      encabezados = [
        "No°",
        "Nombre",
        "Tipo",
        "Esta columna es para marcar si ya cooperó o si está condonado"
      ]

      filas = @desglose.each_with_index.map do |fila, index|
        trabajador = fila[:trabajador]

        observacion = if fila[:condonado]
                        "Condonado"
                      else
                        ""
                      end

        [
          (index + 1).to_s,
          limpiar_texto(trabajador.nombre_completo),
          limpiar_texto(trabajador.tipo_trabajador&.humanize || "-"),
          observacion
        ]
      end

      data = [encabezados] + filas

      @pdf.table(
        data,
        header: true,
        width: @pdf.bounds.width,
        column_widths: {
          0 => 45,
          1 => 360,
          2 => 130,
          3 => @pdf.bounds.width - 45 - 360 - 130
        },
        cell_style: {
          size: 10,
          padding: [6, 6, 6, 6],
          border_width: 1,
          valign: :top,
          overflow: :shrink_to_fit,
          min_font_size: 7
        }
      ) do |table|
        table.row(0).font_style = :bold
        table.row(0).size = 10
        table.row(0).valign = :top

        table.column(0).align = :center
        table.cells.border_color = "000000"

        table.rows(1..-1).height = 26
      end
    end

    def construir_total
      total = @desglose.sum { |fila| fila[:total].to_d }

      @pdf.text "Total a recaudar: #{formatear_moneda(total)}",
                size: 12,
                style: :bold,
                align: :left
    end

    def formatear_fecha(fecha)
      return "Sin definir" if fecha.blank?

      fecha.strftime("%d/%m/%Y")
    end

    def formatear_moneda(monto)
      format("$%.2f", monto.to_d)
    end

    def limpiar_texto(texto)
      texto.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?")
    end
  end
end
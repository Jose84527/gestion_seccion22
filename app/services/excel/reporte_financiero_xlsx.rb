require "caxlsx"

module Excel
  class ReporteFinancieroXlsx
    def initialize(tipo:, fecha_inicio:, fecha_fin:, ingresos:, egresos:, total_ingresos:, total_egresos:, saldo_final:)
      @tipo = tipo
      @fecha_inicio = fecha_inicio
      @fecha_fin = fecha_fin
      @ingresos = ingresos
      @egresos = egresos
      @total_ingresos = total_ingresos.to_d
      @total_egresos = total_egresos.to_d
      @saldo_final = saldo_final.to_d
    end

    def render
      paquete = Axlsx::Package.new
      @workbook = paquete.workbook

      definir_estilos
      hoja_resumen
      hoja_ingresos if @tipo.in?(%w[general ingresos])
      hoja_egresos if @tipo.in?(%w[general egresos])

      paquete.to_stream.read
    end

    private

    def definir_estilos
      @styles = {}

      @styles[:titulo_principal] = @workbook.styles.add_style(
        b: true,
        sz: 18,
        fg_color: "5B2C1F",
        alignment: { horizontal: :center }
      )

      @styles[:subtitulo] = @workbook.styles.add_style(
        b: true,
        sz: 12,
        fg_color: "6B4A3A"
      )

      @styles[:texto_normal] = @workbook.styles.add_style(
        sz: 10,
        fg_color: "2B2B2B"
      )

      @styles[:texto_centrado] = @workbook.styles.add_style(
        sz: 10,
        fg_color: "2B2B2B",
        alignment: { horizontal: :center }
      )

      @styles[:texto_wrap] = @workbook.styles.add_style(
        sz: 10,
        fg_color: "2B2B2B",
        alignment: { wrap_text: true, vertical: :top }
      )

      @styles[:encabezado] = @workbook.styles.add_style(
        b: true,
        sz: 10,
        bg_color: "D99058",
        fg_color: "FFFFFF",
        border: borde_delgado,
        alignment: { horizontal: :center, vertical: :center }
      )

      @styles[:encabezado_secundario] = @workbook.styles.add_style(
        b: true,
        sz: 10,
        bg_color: "EFE2D8",
        fg_color: "5B2C1F",
        border: borde_delgado,
        alignment: { horizontal: :center, vertical: :center }
      )

      @styles[:celda] = @workbook.styles.add_style(
        sz: 10,
        border: borde_delgado,
        alignment: { vertical: :top }
      )

      @styles[:celda_centrada] = @workbook.styles.add_style(
        sz: 10,
        border: borde_delgado,
        alignment: { horizontal: :center, vertical: :center }
      )

      @styles[:celda_wrap] = @workbook.styles.add_style(
        sz: 10,
        border: borde_delgado,
        alignment: { wrap_text: true, vertical: :top }
      )

      @styles[:moneda] = @workbook.styles.add_style(
        sz: 10,
        format_code: "$#,##0.00",
        border: borde_delgado,
        alignment: { horizontal: :right }
      )

      @styles[:moneda_resumen] = @workbook.styles.add_style(
        b: true,
        sz: 13,
        format_code: "$#,##0.00",
        bg_color: "F6EFEA",
        fg_color: "5B2C1F",
        border: borde_delgado,
        alignment: { horizontal: :right }
      )

      @styles[:fecha] = @workbook.styles.add_style(
        sz: 10,
        format_code: "dd/mm/yyyy",
        border: borde_delgado,
        alignment: { horizontal: :center }
      )

      @styles[:fecha_hora] = @workbook.styles.add_style(
        sz: 10,
        format_code: "dd/mm/yyyy hh:mm",
        border: borde_delgado,
        alignment: { horizontal: :center }
      )

      @styles[:total_label] = @workbook.styles.add_style(
        b: true,
        sz: 11,
        bg_color: "EFE2D8",
        fg_color: "5B2C1F",
        border: borde_delgado,
        alignment: { horizontal: :right }
      )

      @styles[:total_monto] = @workbook.styles.add_style(
        b: true,
        sz: 11,
        format_code: "$#,##0.00",
        bg_color: "EFE2D8",
        fg_color: "5B2C1F",
        border: borde_delgado,
        alignment: { horizontal: :right }
      )

      @styles[:positivo] = @workbook.styles.add_style(
        b: true,
        sz: 13,
        format_code: "$#,##0.00",
        bg_color: "DDEEDB",
        fg_color: "276738",
        border: borde_delgado,
        alignment: { horizontal: :right }
      )

      @styles[:negativo] = @workbook.styles.add_style(
        b: true,
        sz: 13,
        format_code: "$#,##0.00",
        bg_color: "F4D7D7",
        fg_color: "8A1F1F",
        border: borde_delgado,
        alignment: { horizontal: :right }
      )
    end

    def hoja_resumen
      @workbook.add_worksheet(name: "Resumen") do |sheet|
        sheet.add_row ["COMITÉ EJECUTIVO DELEGACIONAL D-II-11"]
        sheet.merge_cells "A1:F1"
        sheet["A1"].style = @styles[:titulo_principal]

        sheet.add_row ["SECRETARÍA DE FINANZAS"]
        sheet.merge_cells "A2:F2"
        sheet["A2"].style = @styles[:subtitulo]

        sheet.add_row []
        sheet.add_row ["Reporte financiero", nombre_tipo, "", "Periodo", periodo_texto, ""],
                      style: [
                        @styles[:encabezado_secundario],
                        @styles[:celda],
                        nil,
                        @styles[:encabezado_secundario],
                        @styles[:celda],
                        nil
                      ]

        sheet.add_row []
        sheet.add_row ["Resumen general"], style: [@styles[:subtitulo]]
        sheet.merge_cells "A6:F6"

        sheet.add_row ["Indicador", "Valor", "", "Detalle", "Valor", ""],
                      style: [
                        @styles[:encabezado],
                        @styles[:encabezado],
                        nil,
                        @styles[:encabezado],
                        @styles[:encabezado],
                        nil
                      ]

        sheet.add_row [
          "Ingresos confirmados",
          @total_ingresos,
          "",
          "Número de ingresos",
          @ingresos.size,
          ""
        ], style: [
          @styles[:celda],
          @styles[:moneda_resumen],
          nil,
          @styles[:celda],
          @styles[:celda_centrada],
          nil
        ]

        sheet.add_row [
          "Egresos confirmados",
          @total_egresos,
          "",
          "Número de egresos",
          @egresos.size,
          ""
        ], style: [
          @styles[:celda],
          @styles[:moneda_resumen],
          nil,
          @styles[:celda],
          @styles[:celda_centrada],
          nil
        ]

        sheet.add_row [
          "Saldo final",
          @saldo_final,
          "",
          "Tipo de reporte",
          nombre_tipo,
          ""
        ], style: [
          @styles[:celda],
          @saldo_final.negative? ? @styles[:negativo] : @styles[:positivo],
          nil,
          @styles[:celda],
          @styles[:celda],
          nil
        ]

        sheet.add_row []
        sheet.add_row ["Interpretación"], style: [@styles[:subtitulo]]
        sheet.merge_cells "A12:F12"

        sheet.add_row [
          "El saldo final se calcula restando los egresos confirmados a los ingresos confirmados. Solo se consideran movimientos confirmados dentro del periodo seleccionado."
        ], style: [@styles[:texto_wrap]]
        sheet.merge_cells "A13:F13"

        sheet.add_row []
        sheet.add_row ["Resumen para gráficas"], style: [@styles[:subtitulo]]
        sheet.merge_cells "A15:F15"

        sheet.add_row ["Concepto", "Monto"],
                      style: [@styles[:encabezado], @styles[:encabezado]]

        sheet.add_row ["Ingresos confirmados", @total_ingresos],
                      style: [@styles[:celda], @styles[:moneda]]

        sheet.add_row ["Egresos confirmados", @total_egresos],
                      style: [@styles[:celda], @styles[:moneda]]

        sheet.add_row ["Saldo final", @saldo_final],
                      style: [@styles[:celda], @saldo_final.negative? ? @styles[:negativo] : @styles[:positivo]]

        sheet.column_widths 28, 22, 4, 24, 28, 4
      end
    end

    def hoja_ingresos
      @workbook.add_worksheet(name: "Detalle ingresos") do |sheet|
        sheet.add_row ["DETALLE DE INGRESOS CONFIRMADOS"]
        sheet.merge_cells "A1:H1"
        sheet["A1"].style = @styles[:titulo_principal]

        sheet.add_row ["Periodo", periodo_texto]
        sheet["A2"].style = @styles[:encabezado_secundario]
        sheet["B2"].style = @styles[:celda]

        sheet.add_row []
        sheet.add_row [
          "No.",
          "Cooperación",
          "Fecha de confirmación",
          "Conceptos",
          "Condonados",
          "Total",
          "Estado",
          "Observaciones"
        ], style: Array.new(8, @styles[:encabezado])

        @ingresos.each_with_index do |cooperacion, index|
          sheet.add_row [
            index + 1,
            cooperacion.nombre,
            cooperacion.confirmada_at,
            cooperacion.cantidad_conceptos,
            cooperacion.cantidad_condonados,
            cooperacion.total_esperado.to_d,
            cooperacion.estado.to_s.humanize,
            texto_observaciones_cooperacion(cooperacion)
          ], style: [
            @styles[:celda_centrada],
            @styles[:celda_wrap],
            @styles[:fecha_hora],
            @styles[:celda_centrada],
            @styles[:celda_centrada],
            @styles[:moneda],
            @styles[:celda_centrada],
            @styles[:celda_wrap]
          ]
        end

        sheet.add_row []
        sheet.add_row [
          "",
          "",
          "",
          "",
          "Total ingresos",
          @total_ingresos,
          "",
          ""
        ], style: [
          nil,
          nil,
          nil,
          nil,
          @styles[:total_label],
          @styles[:total_monto],
          nil,
          nil
        ]

        sheet.auto_filter = "A4:H#{[4 + @ingresos.size, 4].max}"
        sheet.sheet_view.pane do |pane|
          pane.top_left_cell = "A5"
          pane.state = :frozen
          pane.y_split = 4
        end

        sheet.column_widths 8, 36, 24, 14, 14, 18, 16, 45
      end
    end

    def hoja_egresos
      @workbook.add_worksheet(name: "Detalle egresos") do |sheet|
        sheet.add_row ["DETALLE DE EGRESOS CONFIRMADOS"]
        sheet.merge_cells "A1:H1"
        sheet["A1"].style = @styles[:titulo_principal]

        sheet.add_row ["Periodo", periodo_texto]
        sheet["A2"].style = @styles[:encabezado_secundario]
        sheet["B2"].style = @styles[:celda]

        sheet.add_row []
        sheet.add_row [
          "No.",
          "Folio N.P.",
          "Fecha del egreso",
          "Concepto",
          "Confirmado el",
          "Monto",
          "Estado",
          "Observaciones evidencia"
        ], style: Array.new(8, @styles[:encabezado])

        @egresos.each_with_index do |egreso, index|
          sheet.add_row [
            index + 1,
            egreso.folio_np,
            egreso.fecha_egreso,
            egreso.concepto,
            egreso.confirmado_at,
            egreso.monto.to_d,
            egreso.estado.to_s.humanize,
            egreso.observaciones_evidencia.to_s
          ], style: [
            @styles[:celda_centrada],
            @styles[:celda_centrada],
            @styles[:fecha],
            @styles[:celda_wrap],
            @styles[:fecha_hora],
            @styles[:moneda],
            @styles[:celda_centrada],
            @styles[:celda_wrap]
          ]
        end

        sheet.add_row []
        sheet.add_row [
          "",
          "",
          "",
          "",
          "Total egresos",
          @total_egresos,
          "",
          ""
        ], style: [
          nil,
          nil,
          nil,
          nil,
          @styles[:total_label],
          @styles[:total_monto],
          nil,
          nil
        ]

        sheet.auto_filter = "A4:H#{[4 + @egresos.size, 4].max}"
        sheet.sheet_view.pane do |pane|
          pane.top_left_cell = "A5"
          pane.state = :frozen
          pane.y_split = 4
        end

        sheet.column_widths 8, 16, 18, 42, 24, 18, 16, 45
      end
    end

    def texto_observaciones_cooperacion(cooperacion)
      if cooperacion.respond_to?(:observaciones_confirmacion)
        cooperacion.observaciones_confirmacion.to_s
      else
        ""
      end
    end

    def periodo_texto
      inicio = @fecha_inicio&.strftime("%d/%m/%Y") || "inicio"
      fin = @fecha_fin&.strftime("%d/%m/%Y") || "actualidad"

      "#{inicio} - #{fin}"
    end

    def nombre_tipo
      case @tipo
      when "ingresos"
        "Solo ingresos"
      when "egresos"
        "Solo egresos"
      else
        "Reporte general"
      end
    end

    def borde_delgado
      {
        style: :thin,
        color: "D9CFC8"
      }
    end
  end
end
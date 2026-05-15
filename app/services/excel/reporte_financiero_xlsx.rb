require "caxlsx"

module Excel
  class ReporteFinancieroXlsx
    def initialize(
      tipo:,
      fecha_inicio:,
      fecha_fin:,
      ingresos:,
      egresos:,
      total_ingresos:,
      total_egresos:,
      saldo_final:,
      cuenta_financiera: nil,
      modo_global_por_cuentas: false,
      reportes_por_cuenta: []
    )
      @tipo = tipo
      @fecha_inicio = fecha_inicio
      @fecha_fin = fecha_fin
      @ingresos = Array(ingresos)
      @egresos = Array(egresos)
      @total_ingresos = total_ingresos.to_d
      @total_egresos = total_egresos.to_d
      @saldo_final = saldo_final.to_d
      @cuenta_financiera = cuenta_financiera
      @modo_global_por_cuentas = modo_global_por_cuentas
      @reportes_por_cuenta = Array(reportes_por_cuenta)
    end

    def render
      paquete = Axlsx::Package.new
      @workbook = paquete.workbook

      definir_estilos

      if @modo_global_por_cuentas
        hoja_resumen_global

        @reportes_por_cuenta.each_with_index do |reporte, index|
          hoja_resumen_cuenta(reporte, index + 1)

          if mostrar_ingresos?
            hoja_ingresos(
              Array(reporte[:ingresos]),
              reporte[:total_ingresos],
              "Ingresos #{index + 1}",
              reporte[:cuenta],
              reporte[:nombre_cuenta]
            )
          end

          if mostrar_egresos?
            hoja_egresos(
              Array(reporte[:egresos]),
              reporte[:total_egresos],
              "Egresos #{index + 1}",
              reporte[:cuenta],
              reporte[:nombre_cuenta]
            )
          end
        end
      else
        hoja_resumen_individual
        hoja_ingresos(@ingresos, @total_ingresos, "Detalle ingresos", @cuenta_financiera, nil) if mostrar_ingresos?
        hoja_egresos(@egresos, @total_egresos, "Detalle egresos", @cuenta_financiera, nil) if mostrar_egresos?
      end

      paquete.to_stream.read
    end

    private

    def mostrar_ingresos?
      %w[general ingresos].include?(@tipo)
    end

    def mostrar_egresos?
      %w[general egresos].include?(@tipo)
    end

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

    def hoja_resumen_global
      @workbook.add_worksheet(name: "Resumen general") do |sheet|
        sheet.add_row ["COMITÉ EJECUTIVO DELEGACIONAL D-II-11"]
        sheet.merge_cells "A1:F1"
        sheet["A1"].style = @styles[:titulo_principal]

        sheet.add_row ["REPORTE FINANCIERO POR CUENTAS"]
        sheet.merge_cells "A2:F2"
        sheet["A2"].style = @styles[:subtitulo]

        sheet.add_row []
        sheet.add_row ["Tipo de reporte", nombre_tipo, "", "Periodo", periodo_texto, ""],
                      style: [
                        @styles[:encabezado_secundario],
                        @styles[:celda],
                        nil,
                        @styles[:encabezado_secundario],
                        @styles[:celda],
                        nil
                      ]

        sheet.add_row []
        sheet.add_row [
          "Cuenta financiera",
          "Ingresos confirmados",
          "Egresos confirmados",
          "Saldo final",
          "No. ingresos",
          "No. egresos"
        ], style: Array.new(6, @styles[:encabezado])

        @reportes_por_cuenta.each do |reporte|
          total_ingresos = reporte[:total_ingresos].to_d
          total_egresos = reporte[:total_egresos].to_d
          saldo_final = reporte[:saldo_final].to_d

          sheet.add_row [
            nombre_cuenta_reporte(reporte),
            total_ingresos,
            total_egresos,
            saldo_final,
            Array(reporte[:ingresos]).size,
            Array(reporte[:egresos]).size
          ], style: [
            @styles[:celda_wrap],
            @styles[:moneda],
            @styles[:moneda],
            saldo_final.negative? ? @styles[:negativo] : @styles[:positivo],
            @styles[:celda_centrada],
            @styles[:celda_centrada]
          ]
        end

        sheet.column_widths 34, 22, 22, 22, 15, 15
      end
    end

    def hoja_resumen_cuenta(reporte, numero)
      nombre = nombre_hoja("Resumen #{numero}")
      total_ingresos = reporte[:total_ingresos].to_d
      total_egresos = reporte[:total_egresos].to_d
      saldo_final = reporte[:saldo_final].to_d

      @workbook.add_worksheet(name: nombre) do |sheet|
        sheet.add_row ["RESUMEN FINANCIERO"]
        sheet.merge_cells "A1:F1"
        sheet["A1"].style = @styles[:titulo_principal]

        sheet.add_row [nombre_cuenta_reporte(reporte)]
        sheet.merge_cells "A2:F2"
        sheet["A2"].style = @styles[:subtitulo]

        sheet.add_row []
        sheet.add_row ["Tipo de reporte", nombre_tipo, "", "Periodo", periodo_texto, ""],
                      style: [
                        @styles[:encabezado_secundario],
                        @styles[:celda],
                        nil,
                        @styles[:encabezado_secundario],
                        @styles[:celda],
                        nil
                      ]

        sheet.add_row []
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
          total_ingresos,
          "",
          "Número de ingresos",
          Array(reporte[:ingresos]).size,
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
          total_egresos,
          "",
          "Número de egresos",
          Array(reporte[:egresos]).size,
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
          saldo_final,
          "",
          "Cuenta financiera",
          nombre_cuenta_reporte(reporte),
          ""
        ], style: [
          @styles[:celda],
          saldo_final.negative? ? @styles[:negativo] : @styles[:positivo],
          nil,
          @styles[:celda],
          @styles[:celda],
          nil
        ]

        sheet.column_widths 28, 22, 4, 24, 30, 4
      end
    end

    def hoja_resumen_individual
      reporte = {
        cuenta: @cuenta_financiera,
        nombre_cuenta: @cuenta_financiera&.nombre || "Todas las cuentas financieras",
        ingresos: @ingresos,
        egresos: @egresos,
        total_ingresos: @total_ingresos,
        total_egresos: @total_egresos,
        saldo_final: @saldo_final
      }

      hoja_resumen_cuenta(reporte, 1)
    end

    def hoja_ingresos(ingresos, total_ingresos, nombre, cuenta, nombre_cuenta)
      ingresos = Array(ingresos)

      @workbook.add_worksheet(name: nombre_hoja(nombre)) do |sheet|
        sheet.add_row ["DETALLE DE INGRESOS CONFIRMADOS"]
        sheet.merge_cells "A1:H1"
        sheet["A1"].style = @styles[:titulo_principal]

        sheet.add_row ["Cuenta financiera", nombre_cuenta_documento(cuenta, nombre_cuenta), "", "Periodo", periodo_texto]
        sheet["A2"].style = @styles[:encabezado_secundario]
        sheet["B2"].style = @styles[:celda]
        sheet["D2"].style = @styles[:encabezado_secundario]
        sheet["E2"].style = @styles[:celda]

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

        ingresos.each_with_index do |cooperacion, index|
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
        sheet.add_row ["", "", "", "", "Total ingresos", total_ingresos.to_d, "", ""],
                      style: [nil, nil, nil, nil, @styles[:total_label], @styles[:total_monto], nil, nil]

        sheet.auto_filter = "A4:H#{[4 + ingresos.size, 4].max}"
        congelar_encabezado(sheet)
        sheet.column_widths 8, 36, 24, 14, 14, 18, 16, 45
      end
    end

    def hoja_egresos(egresos, total_egresos, nombre, cuenta, nombre_cuenta)
      egresos = Array(egresos)

      @workbook.add_worksheet(name: nombre_hoja(nombre)) do |sheet|
        sheet.add_row ["DETALLE DE EGRESOS CONFIRMADOS"]
        sheet.merge_cells "A1:H1"
        sheet["A1"].style = @styles[:titulo_principal]

        sheet.add_row ["Cuenta financiera", nombre_cuenta_documento(cuenta, nombre_cuenta), "", "Periodo", periodo_texto]
        sheet["A2"].style = @styles[:encabezado_secundario]
        sheet["B2"].style = @styles[:celda]
        sheet["D2"].style = @styles[:encabezado_secundario]
        sheet["E2"].style = @styles[:celda]

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

        egresos.each_with_index do |egreso, index|
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
        sheet.add_row ["", "", "", "", "Total egresos", total_egresos.to_d, "", ""],
                      style: [nil, nil, nil, nil, @styles[:total_label], @styles[:total_monto], nil, nil]

        sheet.auto_filter = "A4:H#{[4 + egresos.size, 4].max}"
        congelar_encabezado(sheet)
        sheet.column_widths 8, 16, 18, 42, 24, 18, 16, 45
      end
    end

    def congelar_encabezado(sheet)
      sheet.sheet_view.pane do |pane|
        pane.top_left_cell = "A5"
        pane.state = :frozen
        pane.y_split = 4
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

    def nombre_cuenta_reporte(reporte)
      reporte[:nombre_cuenta].presence ||
        reporte[:cuenta]&.nombre.presence ||
        "Sin cuenta financiera"
    end

    def nombre_cuenta_documento(cuenta, nombre_cuenta)
      nombre_cuenta.to_s.presence ||
        cuenta&.nombre.to_s.presence ||
        "Sin cuenta financiera"
    end

    def nombre_hoja(nombre)
      nombre.to_s.gsub(/[\\\/\?\*\[\]:]/, "-").first(31)
    end

    def borde_delgado
      {
        style: :thin,
        color: "D9CFC8"
      }
    end
  end
end
require "prawn"

module Pdf
  class CooperacionRecibosPdf
    def initialize(cooperacion)
      @cooperacion = cooperacion
      @desglose = cooperacion.desglose_por_trabajador
    end

    def render
      Prawn::Document.new(page_size: "LETTER", margin: 36) do |pdf|
        @pdf = pdf

        @desglose.each_with_index do |fila, index|
          @pdf.start_new_page unless index.zero?

          trabajador = fila[:trabajador]

          linea("SISTEMA INTERNO - SECCION 22")
          linea("RECIBO DE COOPERACION")
          linea("")
          linea("Cooperacion: #{@cooperacion.nombre}")
          linea("Vigencia: #{fecha(@cooperacion.fecha_inicio_vigencia)} - #{fecha(@cooperacion.fecha_fin_vigencia)}")
          linea("Estado de corrida: #{@cooperacion.estado.humanize}")
          linea("Generado: #{Time.current.strftime('%d/%m/%Y %H:%M')}")
          linea("-" * 80)

          linea("DATOS DEL TRABAJADOR")
          linea("Nombre: #{trabajador.nombre_completo}")
          linea("Tipo: #{trabajador.tipo_trabajador&.humanize || '-'}")
          linea("RFC: #{trabajador.rfc}")
          linea("Clave de cobro: #{trabajador.clave_cobro}")
          linea("Categoria: #{trabajador.concepto07_nivel&.nombre || '-'}")
          linea("Concepto 07: #{moneda(fila[:concepto07])}")
          linea("-" * 80)

          if fila[:condonado]
            linea("ESTADO: CONDONADO")
            linea("Este trabajador aparece como condonado en esta corrida de cooperacion.")
            linea("TOTAL: $0.00")
          else
            linea("CONCEPTOS")
            fila[:conceptos].each do |concepto|
              linea("Concepto: #{concepto[:nombre]}")
              linea("Tipo: #{concepto[:tipo_cooperacion].to_s.humanize}")
              linea("Monto fijo: #{concepto[:monto_fijo].present? ? moneda(concepto[:monto_fijo]) : '-'}")
              linea("Porcentaje: #{concepto[:porcentaje].present? ? "#{concepto[:porcentaje]}%" : '-'}")
              linea("Importe: #{moneda(concepto[:importe])}")
              linea("-" * 40)
            end

            linea("TOTAL A COOPERAR: #{moneda(fila[:total])}")
          end

          linea("")
          linea("Firma / recibido: ________________________________")
        end
      end.render
    end

    private

    def linea(texto)
      @pdf.text limpiar(texto.to_s), size: 10
    end

    def fecha(valor)
      valor.present? ? valor.strftime("%d/%m/%Y") : "-"
    end

    def moneda(valor)
      format("$%.2f", valor.to_d)
    end

    def limpiar(texto)
      texto.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?")
    end
  end
end
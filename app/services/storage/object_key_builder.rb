module Storage
  class ObjectKeyBuilder
    class << self
      def construir(modulo:, categoria:, nombre_archivo:, entidad_id: nil, fecha: Date.current)
        partes = []
        partes << normalizar_segmento(modulo)
        partes << entidad_id.to_s if entidad_id.present?
        partes << normalizar_segmento(categoria)
        partes << fecha.year.to_s
        partes << formato_mes(fecha.month)
        partes << sanitizar_nombre_archivo(nombre_archivo)

        partes.join("/")
      end

      private

      def normalizar_segmento(valor)
        valor.to_s.strip.downcase.gsub(/\s+/, "_")
      end

      def formato_mes(mes)
        mes.to_s.rjust(2, "0")
      end

      def sanitizar_nombre_archivo(nombre_archivo)
        base = File.basename(nombre_archivo.to_s)

        base
          .unicode_normalize(:nfkd)
          .encode("ASCII", replace: "")
          .gsub(/[^\w.\-]/, "_")
          .gsub(/_+/, "_")
          .downcase
      end
    end
  end
end
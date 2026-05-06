class Cooperacion < ApplicationRecord
  self.table_name = "cooperaciones"

  ESTADOS = %w[activa completada cancelada].freeze

  belongs_to :confirmada_por,
             class_name: "Usuario",
             optional: true

  has_many :cooperacion_conceptos,
           -> { order(:posicion, :id) },
           dependent: :destroy

  has_many :cooperacion_condonados,
           dependent: :destroy

  has_many :trabajadores_condonados,
           through: :cooperacion_condonados,
           source: :trabajador

  has_many :cooperacion_detalles_confirmados,
         class_name: "CooperacionDetalleConfirmado",
         dependent: :destroy

  accepts_nested_attributes_for :cooperacion_conceptos,
                                allow_destroy: true

  accepts_nested_attributes_for :cooperacion_condonados,
                                allow_destroy: true

  enum :estado,
       {
         activa: "activa",
         completada: "completada",
         cancelada: "cancelada"
       },
       default: :activa

  before_validation :normalizar_campos

  validates :nombre,
            presence: { message: "es obligatorio" },
            length: { minimum: 3, maximum: 100, message: "debe tener entre 3 y 100 caracteres" }

  validates :estado,
            presence: { message: "es obligatorio" },
            inclusion: { in: ESTADOS, message: "no es válido" }

  validate :fecha_fin_no_menor_a_inicio
  validate :debe_tener_al_menos_un_concepto

  scope :recientes, -> { order(created_at: :desc) }

  scope :buscar_por_nombre, lambda { |termino|
    return all if termino.blank?

    termino_limpio = ActiveRecord::Base.sanitize_sql_like(termino.to_s.strip)

    where("nombre ILIKE :q", q: "%#{termino_limpio}%")
  }

  scope :filtrar_por_estado, lambda { |estado|
    return all if estado.blank?
    return all unless ESTADOS.include?(estado)

    where(estado: estado)
  }

  def conceptos_validos
    cooperacion_conceptos.reject(&:marked_for_destruction?)
  end

  def condonados_validos
    cooperacion_condonados.reject(&:marked_for_destruction?)
  end

  def trabajadores_para_calculo
    Trabajador.includes(:concepto07_nivel)
              .where(estado_trabajador: "activo")
              .ordenados
  end

  def trabajador_condonado?(trabajador)
    condonados_validos.any? do |condonado|
      condonado.trabajador_id == trabajador.id
    end
  end

  def total_para_trabajador(trabajador)
    return 0.to_d if trabajador_condonado?(trabajador)

    conceptos_validos.sum do |concepto|
      concepto.monto_para_trabajador(trabajador)
    end
  end

  def desglose_para_trabajador(trabajador)
    condonado = trabajador_condonado?(trabajador)

    conceptos = conceptos_validos.map do |concepto|
      importe = condonado ? 0.to_d : concepto.monto_para_trabajador(trabajador)

      {
        nombre: concepto.nombre,
        tipo_cooperacion: concepto.tipo_cooperacion,
        monto_fijo: concepto.monto_fijo,
        porcentaje: concepto.porcentaje,
        importe: importe
      }
    end

    {
      trabajador: trabajador,
      trabajador_id: trabajador.id,
      nombre_trabajador: trabajador.nombre_completo,
      tipo_trabajador: trabajador.tipo_trabajador,
      rfc: trabajador.rfc,
      curp: trabajador.curp,
      clave_cobro: trabajador.clave_cobro,
      categoria_nombre: trabajador.concepto07_nivel&.nombre,
      concepto07_monto: trabajador.concepto07_monto || 0,
      condonado: condonado,
      concepto07: trabajador.concepto07_monto || 0,
      conceptos: conceptos,
      detalle_conceptos: conceptos,
      total: condonado ? 0.to_d : conceptos.sum { |concepto| concepto[:importe].to_d }
    }
  end

  def calcular_desglose_dinamico
    trabajadores_para_calculo.map do |trabajador|
      desglose_para_trabajador(trabajador)
    end
  end

  def desglose_por_trabajador
    if completada? && cooperacion_detalles_confirmados.exists?
      return cooperacion_detalles_confirmados.ordenados.map(&:fila_para_desglose)
    end

    calcular_desglose_dinamico
  end

  def total_esperado
    return total_confirmado_snapshot.to_d if completada? && total_confirmado_snapshot.present?

    desglose_por_trabajador.sum do |fila|
      valor_de_fila(fila, :total).to_d
    end
  end

  def cantidad_conceptos
    conceptos_validos.size
  end

  def cantidad_condonados
    if completada? && cooperacion_detalles_confirmados.exists?
      return cooperacion_detalles_confirmados.where(condonado: true).count
    end

    condonados_validos.size
  end

  def generar_snapshot_confirmado!
    filas = calcular_desglose_dinamico

    transaction do
      cooperacion_detalles_confirmados.destroy_all

      total_snapshot = 0.to_d

      filas.each do |fila|
        fila_normalizada = normalizar_fila_desglose(fila)
        total_snapshot += fila_normalizada[:total].to_d

        cooperacion_detalles_confirmados.create!(
          trabajador_id: fila_normalizada[:trabajador_id],
          nombre_trabajador: fila_normalizada[:nombre_trabajador],
          tipo_trabajador: fila_normalizada[:tipo_trabajador],
          rfc: fila_normalizada[:rfc],
          curp: fila_normalizada[:curp],
          clave_cobro: fila_normalizada[:clave_cobro],
          categoria_nombre: fila_normalizada[:categoria_nombre],
          concepto07_monto: fila_normalizada[:concepto07_monto],
          condonado: fila_normalizada[:condonado],
          total: fila_normalizada[:total],
          detalle_conceptos: fila_normalizada[:detalle_conceptos]
        )
      end

      update!(
        total_confirmado_snapshot: total_snapshot,
        snapshot_generado_at: Time.current
      )
    end
  end

  def snapshot_para_historial
    {
      id: id,
      nombre: nombre,
      fecha_inicio_vigencia: fecha_inicio_vigencia,
      fecha_fin_vigencia: fecha_fin_vigencia,
      estado: estado,
      total_esperado: total_esperado.to_s,
      total_confirmado_snapshot: total_confirmado_snapshot&.to_s,
      snapshot_generado_at: snapshot_generado_at,
      conceptos: conceptos_validos.map(&:snapshot_para_historial),
      condonados: condonados_validos.map(&:snapshot_para_historial),
      detalles_confirmados: cooperacion_detalles_confirmados.map(&:snapshot_para_historial),
      confirmada_at: confirmada_at,
      confirmada_por_id: confirmada_por_id,
      lista_confirmacion_pdf_path: lista_confirmacion_pdf_path,
      observaciones_confirmacion: observaciones_confirmacion
    }
  end

  private

  def normalizar_campos
    self.nombre = nombre.to_s.strip.gsub(/\s+/, " ")
    self.estado = "activa" if estado.blank?
  end

  def normalizar_fila_desglose(fila)
    datos = fila.respond_to?(:with_indifferent_access) ? fila.with_indifferent_access : {}
    trabajador = datos[:trabajador]

    detalle_conceptos = datos[:detalle_conceptos].presence || datos[:conceptos].presence || []

    {
      trabajador_id: trabajador&.id || datos[:trabajador_id],
      nombre_trabajador: datos[:nombre_trabajador].presence || datos[:nombre].presence || trabajador&.nombre_completo || "Trabajador sin nombre",
      tipo_trabajador: datos[:tipo_trabajador].presence || trabajador&.tipo_trabajador,
      rfc: datos[:rfc].presence || trabajador&.rfc,
      curp: datos[:curp].presence || trabajador&.curp,
      clave_cobro: datos[:clave_cobro].presence || trabajador&.clave_cobro,
      categoria_nombre: datos[:categoria_nombre].presence || trabajador&.concepto07_nivel&.nombre,
      concepto07_monto: datos[:concepto07_monto].presence || datos[:concepto07].presence || trabajador&.concepto07_monto || 0,
      condonado: ActiveModel::Type::Boolean.new.cast(datos[:condonado]),
      total: datos[:total].to_d,
      detalle_conceptos: normalizar_detalle_conceptos(detalle_conceptos)
    }
  end

  def normalizar_detalle_conceptos(detalle_conceptos)
    Array(detalle_conceptos).map do |concepto|
      datos = concepto.respond_to?(:with_indifferent_access) ? concepto.with_indifferent_access : {}

      {
        nombre: datos[:nombre].to_s,
        tipo_cooperacion: datos[:tipo_cooperacion].to_s,
        monto_fijo: datos[:monto_fijo].to_d.to_s,
        porcentaje: datos[:porcentaje].to_d.to_s,
        importe: datos[:importe].to_d.to_s
      }
    end
  end

  def valor_de_fila(fila, clave)
    return fila[clave] if fila.respond_to?(:[]) && fila[clave].present?
    return fila[clave.to_s] if fila.respond_to?(:[]) && fila[clave.to_s].present?

    nil
  end

  def fecha_fin_no_menor_a_inicio
    return if fecha_inicio_vigencia.blank? || fecha_fin_vigencia.blank?
    return unless fecha_fin_vigencia < fecha_inicio_vigencia

    errors.add(:fecha_fin_vigencia, "no puede ser menor a la fecha de inicio")
  end

  def debe_tener_al_menos_un_concepto
    return if conceptos_validos.any?

    errors.add(:cooperacion_conceptos, "debe incluir al menos un concepto")
  end
end
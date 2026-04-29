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
      condonado: condonado,
      concepto07: trabajador.concepto07_monto || 0,
      conceptos: conceptos,
      total: condonado ? 0.to_d : conceptos.sum { |concepto| concepto[:importe].to_d }
    }
  end

  def desglose_por_trabajador
    trabajadores_para_calculo.map do |trabajador|
      desglose_para_trabajador(trabajador)
    end
  end

  def total_esperado
    desglose_por_trabajador.sum { |fila| fila[:total].to_d }
  end

  def cantidad_conceptos
    conceptos_validos.size
  end

  def cantidad_condonados
    condonados_validos.size
  end

  def snapshot_para_historial
    {
      id: id,
      nombre: nombre,
      fecha_inicio_vigencia: fecha_inicio_vigencia,
      fecha_fin_vigencia: fecha_fin_vigencia,
      estado: estado,
      total_esperado: total_esperado.to_s,
      conceptos: conceptos_validos.map(&:snapshot_para_historial),
      condonados: condonados_validos.map(&:snapshot_para_historial),
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
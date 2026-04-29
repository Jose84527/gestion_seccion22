class CooperacionConcepto < ApplicationRecord
  self.table_name = "cooperacion_conceptos"

  TIPOS_COOPERACION = %w[fija porcentaje mixta].freeze

  belongs_to :cooperacion

  enum :tipo_cooperacion,
       {
         fija: "fija",
         porcentaje: "porcentaje",
         mixta: "mixta"
       },
       prefix: true

  before_validation :normalizar_campos

  validates :nombre,
            presence: { message: "es obligatorio" },
            length: { minimum: 3, maximum: 100, message: "debe tener entre 3 y 100 caracteres" }

  validates :descripcion,
            length: { minimum: 5, message: "debe tener al menos 5 caracteres" },
            allow_blank: true

  validates :tipo_cooperacion,
            presence: { message: "es obligatorio" },
            inclusion: { in: TIPOS_COOPERACION, message: "no es válido" }

  validates :monto_fijo,
            numericality: { greater_than: 0, message: "debe ser mayor a 0" },
            allow_nil: true

  validates :porcentaje,
            numericality: {
              greater_than: 0,
              less_than_or_equal_to: 100,
              message: "debe ser mayor a 0 y menor o igual a 100"
            },
            allow_nil: true

  validate :validar_monto_y_porcentaje_segun_tipo

  def monto_para_trabajador(trabajador)
    base_07 = trabajador.concepto07_monto || 0

    case tipo_cooperacion
    when "fija"
      monto_fijo.to_d
    when "porcentaje"
      base_07.to_d * porcentaje.to_d / 100
    when "mixta"
      monto_fijo.to_d + (base_07.to_d * porcentaje.to_d / 100)
    else
      0.to_d
    end
  end

  def snapshot_para_historial
    {
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      tipo_cooperacion: tipo_cooperacion,
      monto_fijo: monto_fijo&.to_s,
      porcentaje: porcentaje&.to_s,
      posicion: posicion
    }
  end

  private

  def normalizar_campos
    self.nombre = nombre.to_s.strip.gsub(/\s+/, " ")
    self.descripcion = descripcion.to_s.strip.presence
  end

  def validar_monto_y_porcentaje_segun_tipo
    case tipo_cooperacion
    when "fija"
      errors.add(:monto_fijo, "es obligatorio para una cooperación fija") if monto_fijo.blank?
    when "porcentaje"
      errors.add(:porcentaje, "es obligatorio para una cooperación por porcentaje") if porcentaje.blank?
    when "mixta"
      errors.add(:monto_fijo, "es obligatorio para una cooperación mixta") if monto_fijo.blank?
      errors.add(:porcentaje, "es obligatorio para una cooperación mixta") if porcentaje.blank?
    end
  end
end
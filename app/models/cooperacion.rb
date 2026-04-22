class Cooperacion < ApplicationRecord
  self.table_name = "cooperaciones"

  TIPOS_COOPERACION = %w[porcentaje monto_fijo mixta].freeze
  PERIODICIDADES_GENERACION = %w[unica semanal quincenal mensual].freeze

  enum :tipo_cooperacion,
       {
         porcentaje: "porcentaje",
         monto_fijo: "monto_fijo",
         mixta: "mixta"
       },
       prefix: true

  enum :periodicidad_generacion,
       {
         unica: "unica",
         semanal: "semanal",
         quincenal: "quincenal",
         mensual: "mensual"
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
            presence: { message: "es obligatoria" },
            inclusion: { in: TIPOS_COOPERACION, message: "no es válida" }

  validates :periodicidad_generacion,
            presence: { message: "es obligatoria" },
            inclusion: { in: PERIODICIDADES_GENERACION, message: "no es válida" }

  validates :monto_fijo_base,
            numericality: { greater_than_or_equal_to: 0, message: "debe ser mayor o igual a 0" },
            allow_nil: true

  validates :activa,
            inclusion: { in: [true, false], message: "debe ser verdadero o falso" }

  validates :es_recurrente,
            inclusion: { in: [true, false], message: "debe ser verdadero o falso" }

  validate :fecha_fin_no_menor_a_inicio
  validate :monto_fijo_requerido_si_tipo_monto_fijo_o_mixta

  scope :activas, -> { where(activa: true).order(:nombre) }

  def snapshot_para_historial
    {
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      tipo_cooperacion: tipo_cooperacion,
      monto_fijo_base: monto_fijo_base&.to_s,
      es_recurrente: es_recurrente,
      periodicidad_generacion: periodicidad_generacion,
      fecha_inicio_vigencia: fecha_inicio_vigencia,
      fecha_fin_vigencia: fecha_fin_vigencia,
      activa: activa
    }
  end

  private

  def normalizar_campos
    self.nombre = nombre.to_s.strip.gsub(/\s+/, " ")
    self.descripcion = descripcion.to_s.strip.presence
  end

  def fecha_fin_no_menor_a_inicio
    return if fecha_inicio_vigencia.blank? || fecha_fin_vigencia.blank?
    return unless fecha_fin_vigencia < fecha_inicio_vigencia

    errors.add(:fecha_fin_vigencia, "no puede ser menor a la fecha de inicio")
  end

  def monto_fijo_requerido_si_tipo_monto_fijo_o_mixta
    return unless tipo_cooperacion_monto_fijo? || tipo_cooperacion_mixta?
    return if monto_fijo_base.present?

    errors.add(:monto_fijo_base, "es obligatorio para el tipo de cooperación seleccionado")
  end
end
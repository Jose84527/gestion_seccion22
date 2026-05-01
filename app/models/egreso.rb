class Egreso < ApplicationRecord
  ESTADOS = %w[registrado confirmado cancelado].freeze

  enum :estado,
       {
         registrado: "registrado",
         confirmado: "confirmado",
         cancelado: "cancelado"
       },
       default: :registrado

  before_validation :normalizar_campos
  before_validation :asignar_folio_np, on: :create

  validates :numero_np,
            presence: { message: "es obligatorio" },
            numericality: { only_integer: true, greater_than: 0, message: "debe ser mayor a 0" },
            uniqueness: { message: "ya existe" }

  validates :folio_np,
            presence: { message: "es obligatorio" },
            uniqueness: { message: "ya existe" }

  validates :monto,
            presence: { message: "es obligatorio" },
            numericality: { greater_than: 0, message: "debe ser mayor a 0" }

  validates :concepto,
            presence: { message: "es obligatorio" },
            length: { minimum: 3, maximum: 150, message: "debe tener entre 3 y 150 caracteres" }

  validates :fecha_egreso,
            presence: { message: "es obligatoria" }

  validates :estado,
            presence: { message: "es obligatorio" },
            inclusion: { in: ESTADOS, message: "no es válido" }

  validates :observaciones,
            length: { maximum: 500, message: "no puede superar 500 caracteres" },
            allow_blank: true

  validates :observaciones_evidencia,
            length: { maximum: 1500, message: "no puede superar 1500 caracteres" },
            allow_blank: true

  scope :recientes, lambda {
    order(created_at: :desc)
  }

  scope :ordenados_por_folio, lambda {
    order(numero_np: :desc)
  }

  scope :buscar_por_texto, lambda { |termino|
    return all if termino.blank?

    termino_limpio = ActiveRecord::Base.sanitize_sql_like(termino.to_s.strip)

    where(
      "folio_np ILIKE :q OR concepto ILIKE :q",
      q: "%#{termino_limpio}%"
    )
  }

  scope :filtrar_por_estado, lambda { |estado|
    return all if estado.blank?
    return all unless ESTADOS.include?(estado)

    where(estado: estado)
  }

  def editable?
    registrado?
  end

  def cancelable?
    registrado?
  end

  def confirmable?
    registrado?
  end

  def snapshot_para_historial
    {
      id: id,
      numero_np: numero_np,
      folio_np: folio_np,
      monto: monto&.to_s,
      concepto: concepto,
      fecha_egreso: fecha_egreso,
      observaciones: observaciones,
      estado: estado,
      evidencia_pdf_path: evidencia_pdf_path,
      observaciones_evidencia: observaciones_evidencia,
      confirmado_at: confirmado_at
    }
  end

  private

  def normalizar_campos
    self.concepto = concepto.to_s.strip.gsub(/\s+/, " ")
    self.observaciones = observaciones.to_s.strip.presence
    self.observaciones_evidencia = observaciones_evidencia.to_s.strip.presence
    self.estado = "registrado" if estado.blank?
  end

  def asignar_folio_np
    self.numero_np = siguiente_numero_np if numero_np.blank?
    self.folio_np = format("N.P. %04d", numero_np) if folio_np.blank?
  end

  def siguiente_numero_np
    Egreso.maximum(:numero_np).to_i + 1
  end
end
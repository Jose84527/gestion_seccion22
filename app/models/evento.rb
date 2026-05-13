class Evento < ApplicationRecord
  self.table_name = "eventos"

  ESTADOS = %w[programado confirmado cancelado].freeze

  belongs_to :confirmado_por,
             class_name: "Usuario",
             optional: true

  has_many :evento_asistencias,
           dependent: :destroy

  has_many :trabajadores_asistentes,
           through: :evento_asistencias,
           source: :trabajador

  enum :estado,
       {
         programado: "programado",
         confirmado: "confirmado",
         cancelado: "cancelado"
       },
       default: :programado

  before_validation :normalizar_campos

  validates :nombre,
            presence: { message: "es obligatorio" },
            length: { minimum: 3, maximum: 120, message: "debe tener entre 3 y 120 caracteres" }

  validates :descripcion,
            length: { maximum: 1000, message: "no puede superar 1000 caracteres" },
            allow_blank: true

  validates :lugar,
            presence: { message: "es obligatorio" },
            length: { minimum: 3, maximum: 180, message: "debe tener entre 3 y 180 caracteres" }

  validates :fecha_inicio,
            presence: { message: "es obligatoria" }

  validates :fecha_fin,
            presence: { message: "es obligatoria" }

  validates :puntaje,
            presence: { message: "es obligatorio" },
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              message: "debe ser un número entero mayor o igual a 0"
            }

  validates :estado,
            presence: { message: "es obligatorio" },
            inclusion: { in: ESTADOS, message: "no es válido" }

  validates :convocatoria_pdf_path,
            presence: { message: "es obligatoria" }

  validates :observaciones_confirmacion,
            length: { maximum: 1500, message: "no puede superar 1500 caracteres" },
            allow_blank: true

  validate :fecha_fin_no_puede_ser_menor_a_inicio

  scope :recientes, -> { order(created_at: :desc) }
  scope :ordenados_por_fecha, -> { order(fecha_inicio: :desc) }
  scope :proximos, -> { where(estado: "programado").where("fecha_inicio >= ?", Time.current).order(:fecha_inicio) }
  scope :confirmados, -> { where(estado: "confirmado") }

  scope :buscar_por_texto, lambda { |termino|
    return all if termino.blank?

    termino_limpio = ActiveRecord::Base.sanitize_sql_like(termino.to_s.strip)

    where(
      "nombre ILIKE :q OR lugar ILIKE :q OR descripcion ILIKE :q",
      q: "%#{termino_limpio}%"
    )
  }

  scope :filtrar_por_estado, lambda { |estado|
    return all if estado.blank?
    return all unless ESTADOS.include?(estado)

    where(estado: estado)
  }

  def editable?
    programado?
  end

  def cancelable?
    programado?
  end

  def confirmable?
    programado?
  end

  def total_asistentes
    evento_asistencias.size
  end

  def total_puntos_asignados
    evento_asistencias.sum(:puntaje_asignado)
  end

  def snapshot_para_historial
    {
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      lugar: lugar,
      fecha_inicio: fecha_inicio,
      fecha_fin: fecha_fin,
      puntaje: puntaje,
      estado: estado,
      convocatoria_pdf_path: convocatoria_pdf_path,
      lista_participacion_pdf_path: lista_participacion_pdf_path,
      confirmado_at: confirmado_at,
      confirmado_por_id: confirmado_por_id,
      confirmado_por_nombre: confirmado_por&.nombre_usuario,
      observaciones_confirmacion: observaciones_confirmacion,
      total_asistentes: total_asistentes,
      total_puntos_asignados: total_puntos_asignados
    }
  end

  private

  def normalizar_campos
    self.nombre = nombre.to_s.strip.gsub(/\s+/, " ")
    self.descripcion = descripcion.to_s.strip.presence
    self.lugar = lugar.to_s.strip.gsub(/\s+/, " ")
    self.estado = "programado" if estado.blank?
  end

  def fecha_fin_no_puede_ser_menor_a_inicio
    return if fecha_inicio.blank? || fecha_fin.blank?
    return unless fecha_fin < fecha_inicio

    errors.add(:fecha_fin, "no puede ser menor a la fecha de inicio")
  end
end
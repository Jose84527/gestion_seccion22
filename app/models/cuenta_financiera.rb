class CuentaFinanciera < ApplicationRecord
  self.table_name = "cuentas_financieras"

  has_many :usuarios, dependent: :restrict_with_exception
  has_many :cooperaciones, dependent: :restrict_with_exception
  has_many :egresos, dependent: :restrict_with_exception

  before_validation :normalizar_campos

  validates :nombre,
            presence: { message: "es obligatorio" },
            uniqueness: { case_sensitive: false, message: "ya existe" },
            length: { minimum: 3, maximum: 100, message: "debe tener entre 3 y 100 caracteres" }

  validates :responsable_nombre,
            presence: { message: "es obligatorio" },
            length: { minimum: 3, maximum: 120, message: "debe tener entre 3 y 120 caracteres" }

  validates :responsable_puesto,
            presence: { message: "es obligatorio" },
            length: { minimum: 3, maximum: 120, message: "debe tener entre 3 y 120 caracteres" }

  validates :activa,
            inclusion: { in: [true, false], message: "debe ser verdadero o falso" }

  scope :activas, -> { where(activa: true).order(:nombre) }
  scope :ordenadas, -> { order(:nombre) }

  def nombre_completo
    nombre
  end

  def responsable_para_documento
    responsable_nombre.presence || "RESPONSABLE NO ASIGNADO"
  end

  def puesto_para_documento
    responsable_puesto.presence || "PUESTO NO ASIGNADO"
  end

  def snapshot_para_historial
    {
      id: id,
      nombre: nombre,
      responsable_nombre: responsable_nombre,
      responsable_puesto: responsable_puesto,
      activa: activa
    }
  end

  private

  def normalizar_campos
    self.nombre = nombre.to_s.strip.gsub(/\s+/, " ")
    self.responsable_nombre = responsable_nombre.to_s.strip.gsub(/\s+/, " ")
    self.responsable_puesto = responsable_puesto.to_s.strip.gsub(/\s+/, " ")
    self.activa = true if activa.nil?
  end
end
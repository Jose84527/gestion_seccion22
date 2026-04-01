class Concepto07Nivel < ApplicationRecord
  self.table_name = "concepto07_niveles"

  has_many :trabajadores, dependent: :restrict_with_exception

  before_validation :normalizar_clave, :normalizar_nombre

  validates :clave,
            presence: { message: "es obligatoria" },
            uniqueness: { case_sensitive: false, message: "ya está en uso" }

  validates :nombre,
            presence: { message: "es obligatorio" }

  validates :activo,
            inclusion: { in: [true, false], message: "debe ser verdadero o falso" }

  scope :activos, -> { where(activo: true).order(:nombre) }

  private

  def normalizar_clave
    self.clave = clave.to_s.strip.upcase
  end

  def normalizar_nombre
    self.nombre = nombre.to_s.strip
  end
end
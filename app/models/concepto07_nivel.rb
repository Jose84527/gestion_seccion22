class Concepto07Nivel < ApplicationRecord
  self.table_name = "concepto07_niveles"

  has_many :trabajadores, dependent: :restrict_with_exception

  before_validation :normalizar_clave, :normalizar_nombre, :normalizar_descripcion

  validates :clave,
            presence: { message: "es obligatoria" },
            uniqueness: { case_sensitive: false, message: "ya está en uso" },
            length: { minimum: 2, maximum: 20, message: "debe tener entre 2 y 20 caracteres" }

  validates :nombre,
            presence: { message: "es obligatorio" },
            length: { minimum: 3, maximum: 100, message: "debe tener entre 3 y 100 caracteres" }

  validates :descripcion,
            length: { minimum: 5, message: "debe tener al menos 5 caracteres" },
            allow_blank: true

  validates :activo,
            inclusion: { in: [true, false], message: "debe ser verdadero o falso" }

  scope :activos, -> { where(activo: true).order(:nombre) }

  private

  def normalizar_clave
    self.clave = clave.to_s.strip.upcase
  end

  def normalizar_nombre
    self.nombre = nombre.to_s.strip.gsub(/\s+/, " ")
  end

  def normalizar_descripcion
    self.descripcion = descripcion.to_s.strip.presence
  end
end
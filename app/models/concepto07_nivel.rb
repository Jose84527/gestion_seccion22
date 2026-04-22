class Concepto07Nivel < ApplicationRecord
  self.table_name = "concepto07_niveles"

  has_many :trabajadores, dependent: :restrict_with_exception

  before_validation :asignar_clave_automatica, on: :create
  before_validation :normalizar_nombre

  validates :clave,
            presence: { message: "es obligatoria" },
            uniqueness: { case_sensitive: false, message: "ya está en uso" }

  validates :nombre,
            presence: { message: "es obligatorio" },
            uniqueness: { case_sensitive: false, message: "ya está en uso" },
            length: { minimum: 3, maximum: 100, message: "debe tener entre 3 y 100 caracteres" }

  validates :monto_concepto07,
            presence: { message: "es obligatorio" },
            numericality: { greater_than: 0, message: "debe ser mayor a 0" }

  validates :activo,
            inclusion: { in: [true, false], message: "debe ser verdadero o falso" }

  scope :activos, -> { where(activo: true).order(:nombre) }

  def nombre_categoria
    nombre
  end

  def snapshot_para_historial
    {
      id: id,
      clave: clave,
      nombre: nombre,
      monto_concepto07: monto_concepto07&.to_s,
      activo: activo
    }
  end

  private

  def asignar_clave_automatica
    return if clave.present?

    ultimo_numero = self.class.where("clave LIKE ?", "CP-%")
                              .pluck(:clave)
                              .filter_map { |valor| valor[/\ACP-(\d+)\z/, 1]&.to_i }
                              .max.to_i

    self.clave = format("CP-%02d", ultimo_numero + 1)
  end

  def normalizar_nombre
    self.nombre = nombre.to_s.strip.gsub(/\s+/, " ")
  end
end
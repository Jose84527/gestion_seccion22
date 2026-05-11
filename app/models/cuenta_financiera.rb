class CuentaFinanciera < ApplicationRecord
  self.table_name = "cuentas_financieras"

  has_many :usuarios, dependent: :restrict_with_exception
  has_many :cooperaciones, dependent: :restrict_with_exception
  has_many :egresos, dependent: :restrict_with_exception

  validates :nombre,
            presence: { message: "es obligatorio" },
            uniqueness: { case_sensitive: false, message: "ya existe" },
            length: { minimum: 3, maximum: 100, message: "debe tener entre 3 y 100 caracteres" }

  validates :activa,
            inclusion: { in: [true, false], message: "debe ser verdadero o falso" }

  scope :activas, -> { where(activa: true).order(:nombre) }

  def nombre_completo
    nombre
  end
end
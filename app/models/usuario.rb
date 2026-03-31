class Usuario < ApplicationRecord
  has_secure_password

  ROLES_SISTEMA = %w[admin finanzas capturista consulta].freeze

  enum :rol_sistema,
       {
         admin: "admin",
         finanzas: "finanzas",
         capturista: "capturista",
         consulta: "consulta"
       },
       default: :consulta

  before_validation :normalizar_nombre_usuario

  validates :nombre_usuario,
            presence: { message: "es obligatorio" },
            uniqueness: { case_sensitive: false, message: "ya está en uso" }

  validates :rol_sistema,
            presence: { message: "es obligatorio" },
            inclusion: { in: ROLES_SISTEMA, message: "no es válido" }

  validates :activo,
            inclusion: { in: [true, false], message: "debe ser verdadero o falso" }

  validates :password,
            length: { minimum: 6, message: "mínimo 6 caracteres" },
            if: -> { password.present? }

  private

  def normalizar_nombre_usuario
    self.nombre_usuario = nombre_usuario.to_s.strip.downcase
  end
end
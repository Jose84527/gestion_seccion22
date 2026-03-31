class Usuario < ApplicationRecord
  has_secure_password

  # Validaciones
  validates :nombre_completo, presence: { message: "es obligatorio" }

  validates :username,
            presence: { message: "es obligatorio" },
            uniqueness: { message: "ya está en uso" }

  validates :email,
            presence: { message: "es obligatorio" },
            uniqueness: { message: "ya está registrado" },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "no es válido" }

  validates :password,
            presence: { message: "es obligatoria" },
            length: { minimum: 6, message: "mínimo 6 caracteres" }
end
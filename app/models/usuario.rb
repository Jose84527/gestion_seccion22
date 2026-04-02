class Usuario < ApplicationRecord
  has_secure_password validations: false

  belongs_to :trabajador, optional: true

  ROLES_SISTEMA = %w[admin finanzas].freeze

  enum :rol_sistema,
       {
         admin: "admin",
         finanzas: "finanzas"
       },
       default: :finanzas

  before_validation :normalizar_nombre_usuario

  validates :nombre_usuario,
            presence: { message: "es obligatorio" },
            uniqueness: { case_sensitive: false, message: "ya está en uso" },
            length: { minimum: 3, maximum: 30, message: "debe tener entre 3 y 30 caracteres" },
            format: {
              with: /\A[a-z0-9._-]+\z/,
              message: "solo puede contener letras minúsculas, números, punto, guion y guion bajo"
            }

  validates :rol_sistema,
            presence: { message: "es obligatorio" },
            inclusion: { in: ROLES_SISTEMA, message: "no es válido" }

  validates :activo,
            inclusion: { in: [true, false], message: "debe ser verdadero o falso" }

  validates :trabajador_id,
            uniqueness: { message: "ya tiene una cuenta asignada" },
            allow_nil: true

  validates :password,
            presence: { message: "es obligatoria" },
            length: { minimum: 6, maximum: 72, message: "debe tener entre 6 y 72 caracteres" },
            if: :requiere_password?

  validates :password_confirmation,
            presence: { message: "es obligatoria" },
            if: :requiere_password?

  validate :trabajador_obligatorio_para_cuentas_nuevas, on: :create
  validate :password_y_confirmacion_deben_coincidir, if: :requiere_password?

  def nombre_trabajador
    trabajador&.nombre_completo
  end

  def snapshot_para_historial
    {
      id: id,
      nombre_usuario: nombre_usuario,
      rol_sistema: rol_sistema,
      activo: activo,
      trabajador_id: trabajador_id,
      trabajador_nombre: trabajador&.nombre_completo,
      trabajador_rfc: trabajador&.rfc,
      trabajador_clave_cobro: trabajador&.clave_cobro
    }
  end

  private

  def normalizar_nombre_usuario
    self.nombre_usuario = nombre_usuario.to_s.strip.downcase
  end

  def requiere_password?
    new_record? || password.present? || password_confirmation.present?
  end

  def trabajador_obligatorio_para_cuentas_nuevas
    return if trabajador.present?

    errors.add(:trabajador, "es obligatorio")
  end

  def password_y_confirmacion_deben_coincidir
    return if password.blank? || password_confirmation.blank?
    return if password == password_confirmation

    errors.add(:password_confirmation, "no coincide con la contraseña")
  end
end
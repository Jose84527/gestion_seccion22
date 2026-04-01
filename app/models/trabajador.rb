class Trabajador < ApplicationRecord
  self.table_name = "trabajadores"

  belongs_to :concepto07_nivel

enum :sexo,
     {
       hombre: "h",
       mujer: "m"
     }

enum :estado_trabajador,
     {
       activo: "activo",
       baja: "baja",
       suspendido: "suspendido"
     },
     default: :activo

enum :periodicidad_pago,
     {
       semanal: "semanal",
       quincenal: "quincenal",
       mensual: "mensual"
     }

  before_validation :normalizar_cadenas

  validates :nombres,
            presence: { message: "es obligatorio" }

  validates :apellido_paterno,
            presence: { message: "es obligatorio" }

  validates :sexo,
            presence: { message: "es obligatorio" },
            inclusion: { in: sexos.keys, message: "no es válido" }

  validates :fecha_afiliacion,
            presence: { message: "es obligatoria" }

  validates :rfc,
            presence: { message: "es obligatorio" },
            uniqueness: { case_sensitive: false, message: "ya está registrado" }

  validates :curp,
            presence: { message: "es obligatoria" },
            uniqueness: { case_sensitive: false, message: "ya está registrada" }

  validates :clave_cobro,
            presence: { message: "es obligatoria" },
            uniqueness: { case_sensitive: false, message: "ya está registrada" }

  validates :estado_trabajador,
            presence: { message: "es obligatorio" },
            inclusion: { in: estado_trabajadores.keys, message: "no es válido" }

  validates :periodicidad_pago,
            presence: { message: "es obligatoria" },
            inclusion: { in: periodicidad_pagos.keys, message: "no es válida" }

  validates :salario_neto,
            presence: { message: "es obligatorio" },
            numericality: { greater_than_or_equal_to: 0, message: "debe ser mayor o igual a 0" }

  validates :concepto07_nivel,
            presence: { message: "es obligatorio" }

  validates :correo,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "no es válido" },
            allow_blank: true

  validates :codigo_postal,
            format: { with: /\A\d{5}\z/, message: "debe tener 5 dígitos" },
            allow_blank: true

  private

  def normalizar_cadenas
    self.nombres = normalizar_texto(nombres)
    self.apellido_paterno = normalizar_texto(apellido_paterno)
    self.apellido_materno = normalizar_texto(apellido_materno)
    self.rfc = rfc.to_s.strip.upcase
    self.curp = curp.to_s.strip.upcase
    self.clave_cobro = clave_cobro.to_s.strip.upcase
    self.ct = ct.to_s.strip.upcase
    self.correo = correo.to_s.strip.downcase.presence
    self.telefono = telefono.to_s.strip.presence
    self.direccion = direccion.to_s.strip.presence
    self.codigo_postal = codigo_postal.to_s.strip.presence
  end

  def normalizar_texto(valor)
    valor.to_s.strip.presence
  end
end
class Trabajador < ApplicationRecord
  self.table_name = "trabajadores"

  belongs_to :concepto07_nivel
  has_one :usuario, dependent: :restrict_with_exception

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

  scope :ordenados, -> { order(:apellido_paterno, :apellido_materno, :nombres) }

  scope :buscar_por_nombre, lambda { |termino|
    return all if termino.blank?

    termino = termino.to_s.strip
    where(
      "nombres ILIKE :q OR apellido_paterno ILIKE :q OR apellido_materno ILIKE :q",
      q: "%#{termino}%"
    )
  }

  scope :filtrar_por_concepto07, lambda { |concepto07_nivel_id|
    return all if concepto07_nivel_id.blank?

    where(concepto07_nivel_id: concepto07_nivel_id)
  }

  scope :filtrar_por_estado, lambda { |estado|
    return all if estado.blank?

    where(estado_trabajador: estado)
  }

  validates :nombres,
            presence: { message: "es obligatorio" },
            length: { minimum: 3, message: "debe tener al menos 3 caracteres" }

  validates :apellido_paterno,
            presence: { message: "es obligatorio" },
            length: { minimum: 3, message: "debe tener al menos 3 caracteres" }

  validates :apellido_materno,
            length: { minimum: 3, message: "debe tener al menos 3 caracteres" },
            allow_blank: true

  validates :sexo,
            presence: { message: "es obligatorio" },
            inclusion: { in: sexos.keys, message: "no es válido" }

  validates :fecha_afiliacion,
            presence: { message: "es obligatoria" }

  validates :rfc,
            presence: { message: "es obligatorio" },
            uniqueness: { case_sensitive: false, message: "ya está registrado" },
            length: { is: 13, message: "debe tener 13 caracteres" },
            format: { with: /\A[A-ZÑ&]{4}\d{6}[A-Z0-9]{3}\z/, message: "no tiene un formato válido" }

  validates :curp,
            presence: { message: "es obligatoria" },
            uniqueness: { case_sensitive: false, message: "ya está registrada" },
            length: { is: 18, message: "debe tener 18 caracteres" },
            format: { with: /\A[A-Z][AEIOUX][A-Z]{2}\d{6}[HM][A-Z]{5}[A-Z0-9]\d\z/, message: "no tiene un formato válido" }

  validates :clave_cobro,
            presence: { message: "es obligatoria" },
            uniqueness: { case_sensitive: false, message: "ya está registrada" },
            length: { minimum: 3, message: "debe tener al menos 3 caracteres" }

  validates :ct,
            length: { minimum: 2, message: "debe tener al menos 2 caracteres" },
            allow_blank: true

  validates :telefono,
            format: { with: /\A\d{10}\z/, message: "debe tener 10 dígitos" },
            allow_blank: true

  validates :correo,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "no es válido" },
            allow_blank: true

  validates :direccion,
            length: { minimum: 10, message: "debe tener al menos 10 caracteres" },
            allow_blank: true

  validates :codigo_postal,
            format: { with: /\A\d{5}\z/, message: "debe tener 5 dígitos" },
            allow_blank: true

  validates :estado_trabajador,
            presence: { message: "es obligatorio" },
            inclusion: { in: estado_trabajadores.keys, message: "no es válido" }

  validates :periodicidad_pago,
            presence: { message: "es obligatoria" },
            inclusion: { in: periodicidad_pagos.keys, message: "no es válida" }

  validates :salario_neto,
            presence: { message: "es obligatorio" },
            numericality: { greater_than: 0, message: "debe ser mayor a 0" }

  validates :concepto07_nivel,
            presence: { message: "es obligatorio" }

  validate :fecha_afiliacion_no_puede_ser_futura

  def snapshot_para_historial
    {
      id: id,
      nombres: nombres,
      apellido_paterno: apellido_paterno,
      apellido_materno: apellido_materno,
      sexo: sexo,
      fecha_afiliacion: fecha_afiliacion,
      rfc: rfc,
      curp: curp,
      clave_cobro: clave_cobro,
      ct: ct,
      telefono: telefono,
      correo: correo,
      direccion: direccion,
      codigo_postal: codigo_postal,
      estado_trabajador: estado_trabajador,
      salario_neto: salario_neto&.to_s,
      periodicidad_pago: periodicidad_pago,
      concepto07_nivel_id: concepto07_nivel_id,
      concepto07_clave: concepto07_nivel&.clave,
      concepto07_nombre: concepto07_nivel&.nombre
    }
  end

  def nombre_completo
    [nombres, apellido_paterno, apellido_materno].compact.join(" ")
  end

  private

  def normalizar_cadenas
    self.nombres = normalizar_texto(nombres)
    self.apellido_paterno = normalizar_texto(apellido_paterno)
    self.apellido_materno = normalizar_texto(apellido_materno)
    self.rfc = rfc.to_s.strip.upcase
    self.curp = curp.to_s.strip.upcase
    self.clave_cobro = clave_cobro.to_s.strip.upcase
    self.ct = ct.to_s.strip.upcase.presence
    self.correo = correo.to_s.strip.downcase.presence
    self.telefono = telefono.to_s.gsub(/\D/, "").presence
    self.direccion = direccion.to_s.strip.presence
    self.codigo_postal = codigo_postal.to_s.gsub(/\D/, "").presence
  end

  def normalizar_texto(valor)
    valor.to_s.strip.gsub(/\s+/, " ").presence
  end

  def fecha_afiliacion_no_puede_ser_futura
    return if fecha_afiliacion.blank?
    return unless fecha_afiliacion > Date.current

    errors.add(:fecha_afiliacion, "no puede ser futura")
  end
end
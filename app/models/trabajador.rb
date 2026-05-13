class Trabajador < ApplicationRecord
  self.table_name = "trabajadores"

  CT_FIJO = "20DIT0002N".freeze

  belongs_to :concepto07_nivel

  has_one :usuario, dependent: :restrict_with_exception

  has_many :cooperacion_condonados, dependent: :restrict_with_exception
  has_many :cooperaciones_condonadas,
           through: :cooperacion_condonados,
           source: :cooperacion

  has_many :evento_asistencias,
          dependent: :restrict_with_exception

  has_many :eventos_asistidos,
          through: :evento_asistencias,
          source: :evento
  
  enum :sexo,
       {
         hombre: "h",
         mujer: "m"
       }

  enum :tipo_trabajador,
       {
         docente: "docente",
         administrativo: "administrativo"
       },
       prefix: true

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
       },
       default: :quincenal

  before_validation :normalizar_cadenas
  before_validation :asignar_valores_por_default

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

  validates :tipo_trabajador,
            presence: { message: "es obligatorio" },
            inclusion: { in: tipo_trabajadores.keys, message: "no es válido" }

  validates :fecha_ingreso,
            presence: { message: "es obligatoria" }

  validate :fecha_ingreso_no_puede_ser_futura

  validates :rfc,
            presence: { message: "es obligatorio" },
            length: { is: 13, message: "debe tener 13 caracteres" },
            uniqueness: { case_sensitive: false, message: "ya está registrado" }

  validates :curp,
            presence: { message: "es obligatoria" },
            length: { is: 18, message: "debe tener 18 caracteres" },
            uniqueness: { case_sensitive: false, message: "ya está registrada" }

  validates :clave_cobro,
            presence: { message: "es obligatoria" },
            length: { minimum: 3, maximum: 30, message: "debe tener entre 3 y 30 caracteres" },
            uniqueness: { case_sensitive: false, message: "ya está registrada" }

  validates :ct,
            presence: { message: "es obligatorio" }

  validates :telefono,
            format: { with: /\A\d{10}\z/, message: "debe tener 10 dígitos" },
            allow_blank: true

  validates :correo,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "no es válido" },
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

  validates :concepto07_nivel,
            presence: { message: "es obligatorio" }

  validates :condonado_habitual,
            inclusion: { in: [true, false], message: "debe ser verdadero o falso" }

  scope :ordenados, lambda {
    order(:apellido_paterno, :apellido_materno, :nombres)
  }

  scope :activos, lambda {
    where(estado_trabajador: "activo").ordenados
  }

  scope :condonados_habituales, lambda {
    where(condonado_habitual: true, estado_trabajador: "activo").ordenados
  }

  scope :buscar_por_texto, lambda { |termino|
    return all if termino.blank?

    termino_limpio = ActiveRecord::Base.sanitize_sql_like(termino.to_s.strip)

    where(
      "nombres ILIKE :q OR apellido_paterno ILIKE :q OR apellido_materno ILIKE :q OR rfc ILIKE :q OR curp ILIKE :q OR clave_cobro ILIKE :q",
      q: "%#{termino_limpio}%"
    )
  }

  scope :filtrar_por_concepto07, lambda { |concepto07_nivel_id|
    return all if concepto07_nivel_id.blank?

    where(concepto07_nivel_id: concepto07_nivel_id)
  }

  scope :filtrar_por_estado, lambda { |estado|
    return all if estado.blank?
    return all unless estado_trabajadores.key?(estado)

    where(estado_trabajador: estado)
  }

  scope :filtrar_por_sexo, lambda { |sexo|
    return all if sexo.blank?
    return all unless sexos.key?(sexo)

    where(sexo: sexo)
  }

  scope :filtrar_por_tipo_trabajador, lambda { |tipo|
    return all if tipo.blank?
    return all unless tipo_trabajadores.key?(tipo)

    where(tipo_trabajador: tipo)
  }

  def nombre_completo
    [
      nombres,
      apellido_paterno,
      apellido_materno
    ].compact_blank.join(" ")
  end

  def concepto07_monto
    concepto07_nivel&.monto_concepto07 || 0
  end

  def snapshot_para_historial
    {
      id: id,
      nombres: nombres,
      apellido_paterno: apellido_paterno,
      apellido_materno: apellido_materno,
      nombre_completo: nombre_completo,
      sexo: sexo,
      tipo_trabajador: tipo_trabajador,
      fecha_ingreso: fecha_ingreso,
      rfc: rfc,
      curp: curp,
      clave_cobro: clave_cobro,
      ct: ct,
      telefono: telefono,
      correo: correo,
      direccion: direccion,
      codigo_postal: codigo_postal,
      estado_trabajador: estado_trabajador,
      periodicidad_pago: periodicidad_pago,
      concepto07_nivel_id: concepto07_nivel_id,
      categoria_nombre: concepto07_nivel&.nombre,
      concepto07: concepto07_nivel&.monto_concepto07&.to_s,
      condonado_habitual: condonado_habitual
    }
  end

  private

  def normalizar_cadenas
    self.nombres = normalizar_texto(nombres)
    self.apellido_paterno = normalizar_texto(apellido_paterno)
    self.apellido_materno = normalizar_texto(apellido_materno)

    self.rfc = rfc.to_s.strip.upcase
    self.curp = curp.to_s.strip.upcase
    self.clave_cobro = clave_cobro.to_s.strip.upcase

    self.ct = ct.to_s.strip.upcase.presence || CT_FIJO

    self.correo = correo.to_s.strip.downcase.presence
    self.telefono = telefono.to_s.strip.presence
    self.direccion = direccion.to_s.strip.presence
    self.codigo_postal = codigo_postal.to_s.strip.presence
  end

  def asignar_valores_por_default
    self.ct = CT_FIJO
    self.estado_trabajador = "activo" if estado_trabajador.blank?
    self.periodicidad_pago = "quincenal" if periodicidad_pago.blank?
    self.condonado_habitual = false if condonado_habitual.nil?
  end

  def normalizar_texto(valor)
    valor.to_s.strip.gsub(/\s+/, " ").presence
  end

  def fecha_ingreso_no_puede_ser_futura
    return if fecha_ingreso.blank?
    return unless fecha_ingreso > Date.current

    errors.add(:fecha_ingreso, "no puede ser futura")
  end
end
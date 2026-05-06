class CooperacionDetalleConfirmado < ApplicationRecord
  self.table_name = "cooperacion_detalles_confirmados"

  belongs_to :cooperacion
  belongs_to :trabajador, optional: true

  validates :nombre_trabajador, presence: true
  validates :concepto07_monto, numericality: { greater_than_or_equal_to: 0 }
  validates :total, numericality: { greater_than_or_equal_to: 0 }
  validates :condonado, inclusion: { in: [true, false] }

  scope :ordenados, lambda {
    order(:nombre_trabajador)
  }

  def snapshot_para_historial
    {
      id: id,
      cooperacion_id: cooperacion_id,
      trabajador_id: trabajador_id,
      nombre_trabajador: nombre_trabajador,
      tipo_trabajador: tipo_trabajador,
      rfc: rfc,
      curp: curp,
      clave_cobro: clave_cobro,
      categoria_nombre: categoria_nombre,
      concepto07_monto: concepto07_monto&.to_s,
      condonado: condonado,
      total: total&.to_s,
      detalle_conceptos: conceptos_para_vista
    }
  end

  def fila_para_desglose
    conceptos = conceptos_para_vista

    {
      trabajador: trabajador,
      trabajador_id: trabajador_id,
      nombre_trabajador: nombre_trabajador,
      tipo_trabajador: tipo_trabajador,
      rfc: rfc,
      curp: curp,
      clave_cobro: clave_cobro,
      categoria_nombre: categoria_nombre,
      concepto07: concepto07_monto.to_d,
      concepto07_monto: concepto07_monto.to_d,
      condonado: condonado,
      total: total.to_d,

      # Estas dos claves se dejan para compatibilidad con vistas y PDFs existentes.
      conceptos: conceptos,
      detalle_conceptos: conceptos
    }
  end

  private

  def conceptos_para_vista
    Array(detalle_conceptos).map do |concepto|
      datos = concepto.respond_to?(:with_indifferent_access) ? concepto.with_indifferent_access : {}

      {
        nombre: datos[:nombre].to_s,
        tipo_cooperacion: datos[:tipo_cooperacion].to_s,
        monto_fijo: datos[:monto_fijo].to_d,
        porcentaje: datos[:porcentaje].to_d,
        importe: datos[:importe].to_d
      }
    end
  end
end
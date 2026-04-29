class CooperacionCondonado < ApplicationRecord
  self.table_name = "cooperacion_condonados"

  belongs_to :cooperacion
  belongs_to :trabajador

  validates :trabajador_id,
            presence: { message: "es obligatorio" },
            uniqueness: {
              scope: :cooperacion_id,
              message: "ya está condonado en esta cooperación"
            }

  def snapshot_para_historial
    {
      id: id,
      trabajador_id: trabajador_id,
      trabajador_nombre: trabajador&.nombre_completo,
      trabajador_rfc: trabajador&.rfc,
      trabajador_tipo: trabajador&.tipo_trabajador
    }
  end
end
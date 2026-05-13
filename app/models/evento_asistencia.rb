class EventoAsistencia < ApplicationRecord
  self.table_name = "evento_asistencias"

  belongs_to :evento
  belongs_to :trabajador

  validates :trabajador_id,
            uniqueness: {
              scope: :evento_id,
              message: "ya fue registrado como asistente en este evento"
            }

  validates :puntaje_asignado,
            presence: { message: "es obligatorio" },
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              message: "debe ser un número entero mayor o igual a 0"
            }

  scope :recientes, -> { order(created_at: :desc) }

  def snapshot_para_historial
    {
      id: id,
      evento_id: evento_id,
      trabajador_id: trabajador_id,
      trabajador_nombre: trabajador&.nombre_completo,
      trabajador_rfc: trabajador&.rfc,
      trabajador_clave_cobro: trabajador&.clave_cobro,
      puntaje_asignado: puntaje_asignado
    }
  end
end
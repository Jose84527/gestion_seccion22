class Historial < ApplicationRecord
  self.table_name = "historiales"

  belongs_to :usuario, optional: true

  enum :accion,
       {
         crear: "crear",
         editar: "editar",
         eliminar: "eliminar"
       }

  validates :nombre_usuario, presence: true
  validates :fecha_evento, presence: true
  validates :accion, presence: true
  validates :modulo, presence: true
  validates :entidad, presence: true

  scope :recientes, -> { order(fecha_evento: :desc, id: :desc) }
end
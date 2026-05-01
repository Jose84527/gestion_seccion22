class AgregarObservacionesEvidenciaAEgresos < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:egresos, :observaciones_evidencia)
      add_column :egresos, :observaciones_evidencia, :text
    end
  end
end
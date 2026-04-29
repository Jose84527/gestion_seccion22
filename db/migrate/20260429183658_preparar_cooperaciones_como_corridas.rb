class PrepararCooperacionesComoCorridas < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:cooperaciones, :estado)
      add_column :cooperaciones, :estado, :string, null: false, default: "activa"
      add_index :cooperaciones, :estado
    end

    unless column_exists?(:cooperaciones, :confirmada_at)
      add_column :cooperaciones, :confirmada_at, :datetime
    end

    unless column_exists?(:cooperaciones, :confirmada_por_id)
      add_reference :cooperaciones,
                    :confirmada_por,
                    foreign_key: { to_table: :usuarios },
                    index: true,
                    null: true
    end

    unless column_exists?(:cooperaciones, :lista_confirmacion_pdf_path)
      add_column :cooperaciones, :lista_confirmacion_pdf_path, :string
    end

    unless column_exists?(:cooperaciones, :observaciones_confirmacion)
      add_column :cooperaciones, :observaciones_confirmacion, :text
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE cooperaciones
          SET estado = CASE
            WHEN activa = TRUE THEN 'activa'
            ELSE 'cancelada'
          END
          WHERE estado IS NULL OR estado = '';
        SQL
      end
    end
  end
end
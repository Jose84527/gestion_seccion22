class CrearEventosYEventoAsistencias < ActiveRecord::Migration[8.1]
  def change
    create_table :eventos do |t|
      t.string :nombre, null: false
      t.text :descripcion
      t.string :lugar, null: false
      t.datetime :fecha_inicio, null: false
      t.datetime :fecha_fin, null: false
      t.integer :puntaje, null: false, default: 0
      t.string :estado, null: false, default: "programado"

      t.string :convocatoria_pdf_path, null: false
      t.string :lista_participacion_pdf_path

      t.datetime :confirmado_at
      t.references :confirmado_por,
                   foreign_key: { to_table: :usuarios },
                   index: true,
                   null: true

      t.text :observaciones_confirmacion

      t.timestamps
    end

    add_index :eventos, :estado
    add_index :eventos, :fecha_inicio
    add_index :eventos, :fecha_fin
    add_index :eventos, :nombre

    create_table :evento_asistencias do |t|
      t.references :evento, null: false, foreign_key: true
      t.references :trabajador, null: false, foreign_key: true
      t.integer :puntaje_asignado, null: false, default: 0

      t.timestamps
    end

    add_index :evento_asistencias,
              [:evento_id, :trabajador_id],
              unique: true,
              name: "idx_evento_asistencias_evento_trabajador"
  end
end
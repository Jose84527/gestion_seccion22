class CongelarCooperacionesConfirmadas < ActiveRecord::Migration[8.1]
  def up
    unless column_exists?(:cooperaciones, :total_confirmado_snapshot)
      add_column :cooperaciones, :total_confirmado_snapshot, :decimal, precision: 12, scale: 2
    end

    unless column_exists?(:cooperaciones, :snapshot_generado_at)
      add_column :cooperaciones, :snapshot_generado_at, :datetime
    end

    return if table_exists?(:cooperacion_detalles_confirmados)

    create_table :cooperacion_detalles_confirmados do |t|
      t.references :cooperacion, null: false, foreign_key: true

      t.bigint :trabajador_id

      t.string :nombre_trabajador, null: false
      t.string :tipo_trabajador
      t.string :rfc
      t.string :curp
      t.string :clave_cobro

      t.string :categoria_nombre
      t.decimal :concepto07_monto, precision: 12, scale: 2, null: false, default: 0

      t.boolean :condonado, null: false, default: false
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0

      t.jsonb :detalle_conceptos, null: false, default: []

      t.timestamps
    end

    add_foreign_key :cooperacion_detalles_confirmados,
                    :trabajadores,
                    column: :trabajador_id,
                    on_delete: :nullify

    add_index :cooperacion_detalles_confirmados,
              [:cooperacion_id, :trabajador_id],
              unique: true,
              name: "idx_detalles_confirmados_coop_trabajador"

    add_index :cooperacion_detalles_confirmados,
              :condonado
  end

  def down
    remove_foreign_key :cooperacion_detalles_confirmados, column: :trabajador_id if foreign_key_exists?(:cooperacion_detalles_confirmados, :trabajadores)

    drop_table :cooperacion_detalles_confirmados if table_exists?(:cooperacion_detalles_confirmados)

    remove_column :cooperaciones, :total_confirmado_snapshot if column_exists?(:cooperaciones, :total_confirmado_snapshot)
    remove_column :cooperaciones, :snapshot_generado_at if column_exists?(:cooperaciones, :snapshot_generado_at)
  end
end
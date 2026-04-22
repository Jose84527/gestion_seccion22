class CreateCooperaciones < ActiveRecord::Migration[8.1]
  def change
    create_table :cooperaciones do |t|
      t.string :nombre, null: false
      t.text :descripcion
      t.string :tipo_cooperacion, null: false
      t.decimal :monto_fijo_base, precision: 12, scale: 2
      t.boolean :es_recurrente, null: false, default: false
      t.string :periodicidad_generacion, null: false
      t.date :fecha_inicio_vigencia
      t.date :fecha_fin_vigencia
      t.boolean :activa, null: false, default: true

      t.timestamps
    end

    add_index :cooperaciones, :nombre
    add_index :cooperaciones, :tipo_cooperacion
    add_index :cooperaciones, :periodicidad_generacion
    add_index :cooperaciones, :activa
  end
end
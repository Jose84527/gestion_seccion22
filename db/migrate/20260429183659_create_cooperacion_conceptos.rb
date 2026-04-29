class CreateCooperacionConceptos < ActiveRecord::Migration[8.1]
  def change
    create_table :cooperacion_conceptos do |t|
      t.references :cooperacion, null: false, foreign_key: true
      t.string :nombre, null: false
      t.text :descripcion
      t.string :tipo_cooperacion, null: false
      t.decimal :monto_fijo, precision: 12, scale: 2
      t.decimal :porcentaje, precision: 5, scale: 2
      t.integer :posicion, null: false, default: 0

      t.timestamps
    end

    add_index :cooperacion_conceptos, :tipo_cooperacion
    add_index :cooperacion_conceptos, :posicion
  end
end
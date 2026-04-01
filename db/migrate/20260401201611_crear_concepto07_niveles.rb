class CrearConcepto07Niveles < ActiveRecord::Migration[8.1]
  def change
    create_table :concepto07_niveles do |t|
      t.string :clave, null: false
      t.string :nombre, null: false
      t.text :descripcion
      t.boolean :activo, null: false, default: true

      t.timestamps
    end

    add_index :concepto07_niveles, :clave, unique: true
    add_index :concepto07_niveles, :activo
  end
end
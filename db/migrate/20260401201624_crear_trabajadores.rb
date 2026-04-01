class CrearTrabajadores < ActiveRecord::Migration[8.1]
  def change
    create_table :trabajadores do |t|
      t.string :nombres, null: false
      t.string :apellido_paterno, null: false
      t.string :apellido_materno
      t.string :sexo, null: false
      t.date :fecha_afiliacion, null: false
      t.string :rfc, null: false
      t.string :curp, null: false
      t.string :clave_cobro, null: false
      t.string :ct
      t.string :telefono
      t.string :correo
      t.text :direccion
      t.string :codigo_postal
      t.string :estado_trabajador, null: false, default: "activo"
      t.decimal :salario_neto, precision: 12, scale: 2, null: false
      t.string :periodicidad_pago, null: false
      t.references :concepto07_nivel, null: false, foreign_key: true

      t.timestamps
    end

    add_index :trabajadores, :rfc, unique: true
    add_index :trabajadores, :curp, unique: true
    add_index :trabajadores, :clave_cobro, unique: true
    add_index :trabajadores, :estado_trabajador
    add_index :trabajadores, :sexo
    add_index :trabajadores, :periodicidad_pago
  end
end
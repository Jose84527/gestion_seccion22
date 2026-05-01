class CreateEgresos < ActiveRecord::Migration[8.1]
  def change
    create_table :egresos do |t|
      t.integer :numero_np, null: false
      t.string :folio_np, null: false
      t.decimal :monto, precision: 12, scale: 2, null: false
      t.string :concepto, null: false
      t.date :fecha_egreso, null: false
      t.text :observaciones
      t.string :estado, null: false, default: "registrado"
      t.string :evidencia_pdf_path
      t.datetime :confirmado_at

      t.timestamps
    end

    add_index :egresos, :numero_np, unique: true
    add_index :egresos, :folio_np, unique: true
    add_index :egresos, :estado
    add_index :egresos, :fecha_egreso
  end
end
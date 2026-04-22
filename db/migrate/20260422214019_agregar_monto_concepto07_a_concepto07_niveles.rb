class AgregarMontoConcepto07AConcepto07Niveles < ActiveRecord::Migration[8.1]
  def change
    add_column :concepto07_niveles,
               :monto_concepto07,
               :decimal,
               precision: 12,
               scale: 2,
               null: false,
               default: 0
  end
end
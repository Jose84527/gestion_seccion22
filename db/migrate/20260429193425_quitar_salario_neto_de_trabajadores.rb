class QuitarSalarioNetoDeTrabajadores < ActiveRecord::Migration[8.1]
  def change
    if column_exists?(:trabajadores, :salario_neto)
      remove_column :trabajadores, :salario_neto, :decimal, precision: 12, scale: 2
    end
  end
end
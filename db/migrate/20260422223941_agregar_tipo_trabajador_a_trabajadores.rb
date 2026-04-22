class AgregarTipoTrabajadorATrabajadores < ActiveRecord::Migration[8.1]
  def change
    add_column :trabajadores, :tipo_trabajador, :string unless column_exists?(:trabajadores, :tipo_trabajador)
  end
end
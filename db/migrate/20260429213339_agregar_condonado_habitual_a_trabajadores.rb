class AgregarCondonadoHabitualATrabajadores < ActiveRecord::Migration[8.1]
  def change
    add_column :trabajadores, :condonado_habitual, :boolean, null: false, default: false unless column_exists?(:trabajadores, :condonado_habitual)
    add_column :trabajadores, :motivo_condonacion_habitual, :text unless column_exists?(:trabajadores, :motivo_condonacion_habitual)

    add_index :trabajadores, :condonado_habitual unless index_exists?(:trabajadores, :condonado_habitual)
  end
end
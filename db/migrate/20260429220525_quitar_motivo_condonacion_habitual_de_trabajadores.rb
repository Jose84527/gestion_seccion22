class QuitarMotivoCondonacionHabitualDeTrabajadores < ActiveRecord::Migration[8.1]
  def up
    if column_exists?(:trabajadores, :motivo_condonacion_habitual)
      remove_column :trabajadores, :motivo_condonacion_habitual, :text
    end
  end

  def down
    unless column_exists?(:trabajadores, :motivo_condonacion_habitual)
      add_column :trabajadores, :motivo_condonacion_habitual, :text
    end
  end
end
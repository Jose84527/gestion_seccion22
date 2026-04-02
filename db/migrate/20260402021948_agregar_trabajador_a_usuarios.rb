class AgregarTrabajadorAUsuarios < ActiveRecord::Migration[8.1]
  def up
    unless column_exists?(:usuarios, :trabajador_id)
      add_reference :usuarios, :trabajador, null: true
    end

    unless index_exists?(:usuarios, :trabajador_id, unique: true)
      add_index :usuarios, :trabajador_id, unique: true
    end

    unless foreign_key_exists?(:usuarios, :trabajadores, column: :trabajador_id)
      add_foreign_key :usuarios, :trabajadores, column: :trabajador_id, on_delete: :restrict
    end
  end

  def down
    if foreign_key_exists?(:usuarios, :trabajadores, column: :trabajador_id)
      remove_foreign_key :usuarios, column: :trabajador_id
    end

    if index_exists?(:usuarios, :trabajador_id, unique: true)
      remove_index :usuarios, column: :trabajador_id
    end

    if column_exists?(:usuarios, :trabajador_id)
      remove_column :usuarios, :trabajador_id
    end
  end
end
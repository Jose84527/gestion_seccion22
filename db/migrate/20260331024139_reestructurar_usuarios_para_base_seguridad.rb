class ReestructurarUsuariosParaBaseSeguridad < ActiveRecord::Migration[8.1]
  def up
    if column_exists?(:usuarios, :username) && !column_exists?(:usuarios, :nombre_usuario)
      rename_column :usuarios, :username, :nombre_usuario
    elsif !column_exists?(:usuarios, :nombre_usuario)
      add_column :usuarios, :nombre_usuario, :string
    end

    add_column :usuarios, :trabajador_id, :bigint unless column_exists?(:usuarios, :trabajador_id)
    add_column :usuarios, :rol_sistema, :string, default: "consulta", null: false unless column_exists?(:usuarios, :rol_sistema)
    add_column :usuarios, :activo, :boolean, default: true, null: false unless column_exists?(:usuarios, :activo)
    add_column :usuarios, :ultimo_acceso_at, :datetime unless column_exists?(:usuarios, :ultimo_acceso_at)

    remove_column :usuarios, :email, :string if column_exists?(:usuarios, :email)
    remove_column :usuarios, :nombre_completo, :string if column_exists?(:usuarios, :nombre_completo)

    change_column_null :usuarios, :nombre_usuario, false if column_exists?(:usuarios, :nombre_usuario)

    add_index :usuarios, :nombre_usuario, unique: true unless index_exists?(:usuarios, :nombre_usuario)
    add_index :usuarios, :trabajador_id, unique: true unless index_exists?(:usuarios, :trabajador_id)
  end

  def down
    remove_index :usuarios, :trabajador_id if index_exists?(:usuarios, :trabajador_id)
    remove_index :usuarios, :nombre_usuario if index_exists?(:usuarios, :nombre_usuario)

    add_column :usuarios, :nombre_completo, :string unless column_exists?(:usuarios, :nombre_completo)

    remove_column :usuarios, :ultimo_acceso_at, :datetime if column_exists?(:usuarios, :ultimo_acceso_at)
    remove_column :usuarios, :activo, :boolean if column_exists?(:usuarios, :activo)
    remove_column :usuarios, :rol_sistema, :string if column_exists?(:usuarios, :rol_sistema)
    remove_column :usuarios, :trabajador_id, :bigint if column_exists?(:usuarios, :trabajador_id)

    if column_exists?(:usuarios, :nombre_usuario) && !column_exists?(:usuarios, :username)
      rename_column :usuarios, :nombre_usuario, :username
    end
  end
end
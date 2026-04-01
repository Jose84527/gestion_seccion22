class AjustarRolesSistemaDeUsuarios < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE usuarios
      SET rol_sistema = 'finanzas'
      WHERE rol_sistema IS NULL
         OR rol_sistema NOT IN ('admin', 'finanzas')
    SQL

    change_column_default :usuarios, :rol_sistema, from: "consulta", to: "finanzas"
    change_column_null :usuarios, :rol_sistema, false
  end

  def down
    change_column_default :usuarios, :rol_sistema, from: "finanzas", to: "consulta"
  end
end
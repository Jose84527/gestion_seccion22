class AjustarFoliosEgresosPorCuentaFinanciera < ActiveRecord::Migration[8.1]
  def up
    cuenta_default_id = select_value <<~SQL.squish
      SELECT id FROM cuentas_financieras
      ORDER BY id ASC
      LIMIT 1
    SQL

    raise "No existe ninguna cuenta financiera para asignar egresos existentes" if cuenta_default_id.blank?

    execute <<~SQL.squish
      UPDATE egresos
      SET cuenta_financiera_id = #{cuenta_default_id}
      WHERE cuenta_financiera_id IS NULL
    SQL

    if index_exists?(:egresos, :numero_np, name: "index_egresos_on_numero_np")
      remove_index :egresos, name: "index_egresos_on_numero_np"
    end

    if index_exists?(:egresos, :folio_np, name: "index_egresos_on_folio_np")
      remove_index :egresos, name: "index_egresos_on_folio_np"
    end

    unless index_exists?(:egresos, [:cuenta_financiera_id, :numero_np], name: "idx_egresos_cuenta_numero_np")
      add_index :egresos,
                [:cuenta_financiera_id, :numero_np],
                unique: true,
                name: "idx_egresos_cuenta_numero_np"
    end

    unless index_exists?(:egresos, [:cuenta_financiera_id, :folio_np], name: "idx_egresos_cuenta_folio_np")
      add_index :egresos,
                [:cuenta_financiera_id, :folio_np],
                unique: true,
                name: "idx_egresos_cuenta_folio_np"
    end

    change_column_null :egresos, :cuenta_financiera_id, false
  end

  def down
    change_column_null :egresos, :cuenta_financiera_id, true

    if index_exists?(:egresos, [:cuenta_financiera_id, :folio_np], name: "idx_egresos_cuenta_folio_np")
      remove_index :egresos, name: "idx_egresos_cuenta_folio_np"
    end

    if index_exists?(:egresos, [:cuenta_financiera_id, :numero_np], name: "idx_egresos_cuenta_numero_np")
      remove_index :egresos, name: "idx_egresos_cuenta_numero_np"
    end

    unless index_exists?(:egresos, :numero_np, name: "index_egresos_on_numero_np")
      add_index :egresos, :numero_np, unique: true, name: "index_egresos_on_numero_np"
    end

    unless index_exists?(:egresos, :folio_np, name: "index_egresos_on_folio_np")
      add_index :egresos, :folio_np, unique: true, name: "index_egresos_on_folio_np"
    end
  end
end
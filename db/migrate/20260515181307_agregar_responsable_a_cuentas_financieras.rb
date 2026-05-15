class AgregarResponsableACuentasFinancieras < ActiveRecord::Migration[8.1]
  def change
    add_column :cuentas_financieras, :responsable_nombre, :string unless column_exists?(:cuentas_financieras, :responsable_nombre)
    add_column :cuentas_financieras, :responsable_puesto, :string unless column_exists?(:cuentas_financieras, :responsable_puesto)
  end
end
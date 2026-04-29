class LimpiarCamposViejosDeCooperaciones < ActiveRecord::Migration[8.1]
  def up
    remove_index :cooperaciones, :tipo_cooperacion if index_exists?(:cooperaciones, :tipo_cooperacion)
    remove_index :cooperaciones, :periodicidad_generacion if index_exists?(:cooperaciones, :periodicidad_generacion)
    remove_index :cooperaciones, :activa if index_exists?(:cooperaciones, :activa)

    remove_column :cooperaciones, :tipo_cooperacion if column_exists?(:cooperaciones, :tipo_cooperacion)
    remove_column :cooperaciones, :monto_fijo_base if column_exists?(:cooperaciones, :monto_fijo_base)
    remove_column :cooperaciones, :es_recurrente if column_exists?(:cooperaciones, :es_recurrente)
    remove_column :cooperaciones, :periodicidad_generacion if column_exists?(:cooperaciones, :periodicidad_generacion)
    remove_column :cooperaciones, :activa if column_exists?(:cooperaciones, :activa)
  end

  def down
    add_column :cooperaciones, :tipo_cooperacion, :string, null: false, default: "fija" unless column_exists?(:cooperaciones, :tipo_cooperacion)
    add_column :cooperaciones, :monto_fijo_base, :decimal, precision: 12, scale: 2 unless column_exists?(:cooperaciones, :monto_fijo_base)
    add_column :cooperaciones, :es_recurrente, :boolean, null: false, default: false unless column_exists?(:cooperaciones, :es_recurrente)
    add_column :cooperaciones, :periodicidad_generacion, :string, null: false, default: "unica" unless column_exists?(:cooperaciones, :periodicidad_generacion)
    add_column :cooperaciones, :activa, :boolean, null: false, default: true unless column_exists?(:cooperaciones, :activa)

    add_index :cooperaciones, :tipo_cooperacion unless index_exists?(:cooperaciones, :tipo_cooperacion)
    add_index :cooperaciones, :periodicidad_generacion unless index_exists?(:cooperaciones, :periodicidad_generacion)
    add_index :cooperaciones, :activa unless index_exists?(:cooperaciones, :activa)
  end
end
class CrearCuentasFinancieras < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:cuentas_financieras)
      create_table :cuentas_financieras do |t|
        t.string :nombre, null: false
        t.text :descripcion
        t.boolean :activa, null: false, default: true

        t.timestamps
      end
    end

    unless index_exists?(:cuentas_financieras, :nombre, unique: true)
      add_index :cuentas_financieras, :nombre, unique: true
    end

    unless column_exists?(:usuarios, :cuenta_financiera_id)
      add_reference :usuarios,
                    :cuenta_financiera,
                    foreign_key: { to_table: :cuentas_financieras },
                    index: true,
                    null: true
    end

    unless column_exists?(:cooperaciones, :cuenta_financiera_id)
      add_reference :cooperaciones,
                    :cuenta_financiera,
                    foreign_key: { to_table: :cuentas_financieras },
                    index: true,
                    null: true
    end

    unless column_exists?(:egresos, :cuenta_financiera_id)
      add_reference :egresos,
                    :cuenta_financiera,
                    foreign_key: { to_table: :cuentas_financieras },
                    index: true,
                    null: true
    end

    cuenta_1_id = asegurar_cuenta_financiera!(
      nombre: "Secretaría de Finanzas 1",
      descripcion: "Cuenta financiera principal de la organización."
    )

    asegurar_cuenta_financiera!(
      nombre: "Secretaría de Finanzas 2",
      descripcion: "Segunda cuenta financiera interna de la organización."
    )

    execute <<~SQL.squish
      UPDATE usuarios
      SET cuenta_financiera_id = #{cuenta_1_id}
      WHERE rol_sistema = 'finanzas'
      AND cuenta_financiera_id IS NULL
    SQL

    execute <<~SQL.squish
      UPDATE cooperaciones
      SET cuenta_financiera_id = #{cuenta_1_id}
      WHERE cuenta_financiera_id IS NULL
    SQL

    execute <<~SQL.squish
      UPDATE egresos
      SET cuenta_financiera_id = #{cuenta_1_id}
      WHERE cuenta_financiera_id IS NULL
    SQL
  end

  def down
    if column_exists?(:egresos, :cuenta_financiera_id)
      remove_reference :egresos,
                       :cuenta_financiera,
                       foreign_key: { to_table: :cuentas_financieras }
    end

    if column_exists?(:cooperaciones, :cuenta_financiera_id)
      remove_reference :cooperaciones,
                       :cuenta_financiera,
                       foreign_key: { to_table: :cuentas_financieras }
    end

    if column_exists?(:usuarios, :cuenta_financiera_id)
      remove_reference :usuarios,
                       :cuenta_financiera,
                       foreign_key: { to_table: :cuentas_financieras }
    end

    drop_table :cuentas_financieras if table_exists?(:cuentas_financieras)
  end

  private

  def asegurar_cuenta_financiera!(nombre:, descripcion:)
    nombre_sql = connection.quote(nombre)
    descripcion_sql = connection.quote(descripcion)
    ahora_sql = connection.quote(Time.current)

    id_existente = select_value <<~SQL.squish
      SELECT id FROM cuentas_financieras
      WHERE nombre = #{nombre_sql}
      LIMIT 1
    SQL

    return id_existente.to_i if id_existente.present?

    select_value(<<~SQL.squish).to_i
      INSERT INTO cuentas_financieras
      (nombre, descripcion, activa, created_at, updated_at)
      VALUES
      (#{nombre_sql}, #{descripcion_sql}, TRUE, #{ahora_sql}, #{ahora_sql})
      RETURNING id
    SQL
  end
end
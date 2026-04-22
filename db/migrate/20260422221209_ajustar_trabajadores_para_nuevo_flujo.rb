class AjustarTrabajadoresParaNuevoFlujo < ActiveRecord::Migration[8.1]
  def up
    if column_exists?(:trabajadores, :fecha_afiliacion) && !column_exists?(:trabajadores, :fecha_ingreso)
      rename_column :trabajadores, :fecha_afiliacion, :fecha_ingreso
    end

    if column_exists?(:trabajadores, :ct)
      change_column_default :trabajadores, :ct, from: nil, to: "20DIT0002N"
      execute <<~SQL
        UPDATE trabajadores
        SET ct = '20DIT0002N'
        WHERE ct IS NULL OR TRIM(ct) = '';
      SQL
    end

    if column_exists?(:trabajadores, :estado_trabajador)
      change_column_default :trabajadores, :estado_trabajador, from: nil, to: "activo"
      execute <<~SQL
        UPDATE trabajadores
        SET estado_trabajador = 'activo'
        WHERE estado_trabajador IS NULL OR TRIM(estado_trabajador) = '';
      SQL
    end

    if column_exists?(:trabajadores, :periodicidad_pago)
      change_column_default :trabajadores, :periodicidad_pago, from: nil, to: "quincenal"
      execute <<~SQL
        UPDATE trabajadores
        SET periodicidad_pago = 'quincenal'
        WHERE periodicidad_pago IS NULL OR TRIM(periodicidad_pago) = '';
      SQL
    end
  end

  def down
    if column_exists?(:trabajadores, :fecha_ingreso) && !column_exists?(:trabajadores, :fecha_afiliacion)
      rename_column :trabajadores, :fecha_ingreso, :fecha_afiliacion
    end

    change_column_default :trabajadores, :ct, from: "20DIT0002N", to: nil if column_exists?(:trabajadores, :ct)
    change_column_default :trabajadores, :estado_trabajador, from: "activo", to: nil if column_exists?(:trabajadores, :estado_trabajador)
    change_column_default :trabajadores, :periodicidad_pago, from: "quincenal", to: nil if column_exists?(:trabajadores, :periodicidad_pago)
  end
end
class CreateCooperacionCondonados < ActiveRecord::Migration[8.1]
  def change
    create_table :cooperacion_condonados do |t|
      t.references :cooperacion, null: false, foreign_key: true
      t.references :trabajador, null: false, foreign_key: true

      t.timestamps
    end

    add_index :cooperacion_condonados,
              [:cooperacion_id, :trabajador_id],
              unique: true,
              name: "idx_cooperacion_condonados_unicos"
  end
end
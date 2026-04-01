class CrearHistoriales < ActiveRecord::Migration[8.1]
  def change
    create_table :historiales do |t|
      t.references :usuario, null: true, foreign_key: { to_table: :usuarios, on_delete: :nullify }
      t.string :nombre_usuario, null: false
      t.datetime :fecha_evento, null: false
      t.string :accion, null: false
      t.string :modulo, null: false
      t.string :entidad, null: false
      t.bigint :registro_id
      t.text :resumen
      t.jsonb :antes_json
      t.jsonb :despues_json
      t.inet :ip
      t.text :user_agent
      t.string :request_id

      t.timestamps
    end

    add_index :historiales, :fecha_evento
    add_index :historiales, :accion
    add_index :historiales, :modulo
  end
end
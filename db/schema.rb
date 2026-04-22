# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_22_223941) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "concepto07_niveles", force: :cascade do |t|
    t.boolean "activo", default: true, null: false
    t.string "clave", null: false
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.decimal "monto_concepto07", precision: 12, scale: 2, default: "0.0", null: false
    t.string "nombre", null: false
    t.datetime "updated_at", null: false
    t.index ["activo"], name: "index_concepto07_niveles_on_activo"
    t.index ["clave"], name: "index_concepto07_niveles_on_clave", unique: true
  end

  create_table "cooperaciones", force: :cascade do |t|
    t.boolean "activa", default: true, null: false
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.boolean "es_recurrente", default: false, null: false
    t.date "fecha_fin_vigencia"
    t.date "fecha_inicio_vigencia"
    t.decimal "monto_fijo_base", precision: 12, scale: 2
    t.string "nombre", null: false
    t.string "periodicidad_generacion", null: false
    t.string "tipo_cooperacion", null: false
    t.datetime "updated_at", null: false
    t.index ["activa"], name: "index_cooperaciones_on_activa"
    t.index ["nombre"], name: "index_cooperaciones_on_nombre"
    t.index ["periodicidad_generacion"], name: "index_cooperaciones_on_periodicidad_generacion"
    t.index ["tipo_cooperacion"], name: "index_cooperaciones_on_tipo_cooperacion"
  end

  create_table "historiales", force: :cascade do |t|
    t.string "accion", null: false
    t.jsonb "antes_json"
    t.datetime "created_at", null: false
    t.jsonb "despues_json"
    t.string "entidad", null: false
    t.datetime "fecha_evento", null: false
    t.inet "ip"
    t.string "modulo", null: false
    t.string "nombre_usuario", null: false
    t.bigint "registro_id"
    t.string "request_id"
    t.text "resumen"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.bigint "usuario_id"
    t.index ["accion"], name: "index_historiales_on_accion"
    t.index ["fecha_evento"], name: "index_historiales_on_fecha_evento"
    t.index ["modulo"], name: "index_historiales_on_modulo"
    t.index ["usuario_id"], name: "index_historiales_on_usuario_id"
  end

  create_table "trabajadores", force: :cascade do |t|
    t.string "apellido_materno"
    t.string "apellido_paterno", null: false
    t.string "clave_cobro", null: false
    t.string "codigo_postal"
    t.bigint "concepto07_nivel_id", null: false
    t.string "correo"
    t.datetime "created_at", null: false
    t.string "ct", default: "20DIT0002N"
    t.string "curp", null: false
    t.text "direccion"
    t.string "estado_trabajador", default: "activo", null: false
    t.date "fecha_ingreso", null: false
    t.string "nombres", null: false
    t.string "periodicidad_pago", default: "quincenal", null: false
    t.string "rfc", null: false
    t.decimal "salario_neto", precision: 12, scale: 2, null: false
    t.string "sexo", null: false
    t.string "telefono"
    t.string "tipo_trabajador"
    t.datetime "updated_at", null: false
    t.index ["clave_cobro"], name: "index_trabajadores_on_clave_cobro", unique: true
    t.index ["concepto07_nivel_id"], name: "index_trabajadores_on_concepto07_nivel_id"
    t.index ["curp"], name: "index_trabajadores_on_curp", unique: true
    t.index ["estado_trabajador"], name: "index_trabajadores_on_estado_trabajador"
    t.index ["periodicidad_pago"], name: "index_trabajadores_on_periodicidad_pago"
    t.index ["rfc"], name: "index_trabajadores_on_rfc", unique: true
    t.index ["sexo"], name: "index_trabajadores_on_sexo"
  end

  create_table "usuarios", force: :cascade do |t|
    t.boolean "activo", default: true, null: false
    t.datetime "created_at", null: false
    t.string "nombre_usuario", null: false
    t.string "password_digest"
    t.string "rol_sistema", default: "finanzas", null: false
    t.bigint "trabajador_id"
    t.datetime "ultimo_acceso_at"
    t.datetime "updated_at", null: false
    t.index ["nombre_usuario"], name: "index_usuarios_on_nombre_usuario", unique: true
    t.index ["trabajador_id"], name: "index_usuarios_on_trabajador_id", unique: true
  end

  add_foreign_key "historiales", "usuarios", on_delete: :nullify
  add_foreign_key "trabajadores", "concepto07_niveles"
  add_foreign_key "usuarios", "trabajadores", on_delete: :restrict
end

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

ActiveRecord::Schema[8.1].define(version: 2026_04_01_020427) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
end

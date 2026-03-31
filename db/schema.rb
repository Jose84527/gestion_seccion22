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

ActiveRecord::Schema[8.1].define(version: 2026_03_31_024139) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "usuarios", force: :cascade do |t|
    t.boolean "activo", default: true, null: false
    t.datetime "created_at", null: false
    t.string "nombre_usuario", null: false
    t.string "password_digest"
    t.string "rol_sistema", default: "consulta", null: false
    t.bigint "trabajador_id"
    t.datetime "ultimo_acceso_at"
    t.datetime "updated_at", null: false
    t.index ["nombre_usuario"], name: "index_usuarios_on_nombre_usuario", unique: true
    t.index ["trabajador_id"], name: "index_usuarios_on_trabajador_id", unique: true
  end
end

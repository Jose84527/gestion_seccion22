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

ActiveRecord::Schema[8.1].define(version: 2026_05_15_181307) do
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

  create_table "cooperacion_conceptos", force: :cascade do |t|
    t.bigint "cooperacion_id", null: false
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.decimal "monto_fijo", precision: 12, scale: 2
    t.string "nombre", null: false
    t.decimal "porcentaje", precision: 5, scale: 2
    t.integer "posicion", default: 0, null: false
    t.string "tipo_cooperacion", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperacion_id"], name: "index_cooperacion_conceptos_on_cooperacion_id"
    t.index ["posicion"], name: "index_cooperacion_conceptos_on_posicion"
    t.index ["tipo_cooperacion"], name: "index_cooperacion_conceptos_on_tipo_cooperacion"
  end

  create_table "cooperacion_condonados", force: :cascade do |t|
    t.bigint "cooperacion_id", null: false
    t.datetime "created_at", null: false
    t.bigint "trabajador_id", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperacion_id", "trabajador_id"], name: "idx_cooperacion_condonados_unicos", unique: true
    t.index ["cooperacion_id"], name: "index_cooperacion_condonados_on_cooperacion_id"
    t.index ["trabajador_id"], name: "index_cooperacion_condonados_on_trabajador_id"
  end

  create_table "cooperacion_detalles_confirmados", force: :cascade do |t|
    t.string "categoria_nombre"
    t.string "clave_cobro"
    t.decimal "concepto07_monto", precision: 12, scale: 2, default: "0.0", null: false
    t.boolean "condonado", default: false, null: false
    t.bigint "cooperacion_id", null: false
    t.datetime "created_at", null: false
    t.string "curp"
    t.jsonb "detalle_conceptos", default: [], null: false
    t.string "nombre_trabajador", null: false
    t.string "rfc"
    t.string "tipo_trabajador"
    t.decimal "total", precision: 12, scale: 2, default: "0.0", null: false
    t.bigint "trabajador_id"
    t.datetime "updated_at", null: false
    t.index ["condonado"], name: "index_cooperacion_detalles_confirmados_on_condonado"
    t.index ["cooperacion_id", "trabajador_id"], name: "idx_detalles_confirmados_coop_trabajador", unique: true
    t.index ["cooperacion_id"], name: "index_cooperacion_detalles_confirmados_on_cooperacion_id"
  end

  create_table "cooperaciones", force: :cascade do |t|
    t.datetime "confirmada_at"
    t.bigint "confirmada_por_id"
    t.datetime "created_at", null: false
    t.bigint "cuenta_financiera_id"
    t.text "descripcion"
    t.string "estado", default: "activa", null: false
    t.date "fecha_fin_vigencia"
    t.date "fecha_inicio_vigencia"
    t.string "lista_confirmacion_pdf_path"
    t.string "nombre", null: false
    t.text "observaciones_confirmacion"
    t.datetime "snapshot_generado_at"
    t.decimal "total_confirmado_snapshot", precision: 12, scale: 2
    t.datetime "updated_at", null: false
    t.index ["confirmada_por_id"], name: "index_cooperaciones_on_confirmada_por_id"
    t.index ["cuenta_financiera_id"], name: "index_cooperaciones_on_cuenta_financiera_id"
    t.index ["estado"], name: "index_cooperaciones_on_estado"
    t.index ["nombre"], name: "index_cooperaciones_on_nombre"
  end

  create_table "cuentas_financieras", force: :cascade do |t|
    t.boolean "activa", default: true, null: false
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.string "nombre", null: false
    t.string "responsable_nombre"
    t.string "responsable_puesto"
    t.datetime "updated_at", null: false
    t.index ["nombre"], name: "index_cuentas_financieras_on_nombre", unique: true
  end

  create_table "egresos", force: :cascade do |t|
    t.string "concepto", null: false
    t.datetime "confirmado_at"
    t.datetime "created_at", null: false
    t.bigint "cuenta_financiera_id", null: false
    t.string "estado", default: "registrado", null: false
    t.string "evidencia_pdf_path"
    t.date "fecha_egreso", null: false
    t.string "folio_np", null: false
    t.decimal "monto", precision: 12, scale: 2, null: false
    t.integer "numero_np", null: false
    t.text "observaciones"
    t.text "observaciones_evidencia"
    t.datetime "updated_at", null: false
    t.index ["cuenta_financiera_id", "folio_np"], name: "idx_egresos_cuenta_folio_np", unique: true
    t.index ["cuenta_financiera_id", "numero_np"], name: "idx_egresos_cuenta_numero_np", unique: true
    t.index ["cuenta_financiera_id"], name: "index_egresos_on_cuenta_financiera_id"
    t.index ["estado"], name: "index_egresos_on_estado"
    t.index ["fecha_egreso"], name: "index_egresos_on_fecha_egreso"
  end

  create_table "evento_asistencias", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "evento_id", null: false
    t.integer "puntaje_asignado", default: 0, null: false
    t.bigint "trabajador_id", null: false
    t.datetime "updated_at", null: false
    t.index ["evento_id", "trabajador_id"], name: "idx_evento_asistencias_evento_trabajador", unique: true
    t.index ["evento_id"], name: "index_evento_asistencias_on_evento_id"
    t.index ["trabajador_id"], name: "index_evento_asistencias_on_trabajador_id"
  end

  create_table "eventos", force: :cascade do |t|
    t.string "acta_pdf_path"
    t.datetime "confirmado_at"
    t.bigint "confirmado_por_id"
    t.string "convocatoria_pdf_path", null: false
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.string "estado", default: "programado", null: false
    t.datetime "fecha_fin", null: false
    t.datetime "fecha_inicio", null: false
    t.string "lista_participacion_pdf_path"
    t.string "lugar", null: false
    t.string "nombre", null: false
    t.text "observaciones_confirmacion"
    t.integer "puntaje", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["confirmado_por_id"], name: "index_eventos_on_confirmado_por_id"
    t.index ["estado"], name: "index_eventos_on_estado"
    t.index ["fecha_fin"], name: "index_eventos_on_fecha_fin"
    t.index ["fecha_inicio"], name: "index_eventos_on_fecha_inicio"
    t.index ["nombre"], name: "index_eventos_on_nombre"
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
    t.boolean "condonado_habitual", default: false, null: false
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
    t.string "sexo", null: false
    t.string "telefono"
    t.string "tipo_trabajador"
    t.datetime "updated_at", null: false
    t.index ["clave_cobro"], name: "index_trabajadores_on_clave_cobro", unique: true
    t.index ["concepto07_nivel_id"], name: "index_trabajadores_on_concepto07_nivel_id"
    t.index ["condonado_habitual"], name: "index_trabajadores_on_condonado_habitual"
    t.index ["curp"], name: "index_trabajadores_on_curp", unique: true
    t.index ["estado_trabajador"], name: "index_trabajadores_on_estado_trabajador"
    t.index ["periodicidad_pago"], name: "index_trabajadores_on_periodicidad_pago"
    t.index ["rfc"], name: "index_trabajadores_on_rfc", unique: true
    t.index ["sexo"], name: "index_trabajadores_on_sexo"
  end

  create_table "usuarios", force: :cascade do |t|
    t.boolean "activo", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "cuenta_financiera_id"
    t.string "nombre_usuario", null: false
    t.string "password_digest"
    t.string "rol_sistema", default: "finanzas", null: false
    t.bigint "trabajador_id"
    t.datetime "ultimo_acceso_at"
    t.datetime "updated_at", null: false
    t.index ["cuenta_financiera_id"], name: "index_usuarios_on_cuenta_financiera_id"
    t.index ["nombre_usuario"], name: "index_usuarios_on_nombre_usuario", unique: true
    t.index ["trabajador_id"], name: "index_usuarios_on_trabajador_id", unique: true
  end

  add_foreign_key "cooperacion_conceptos", "cooperaciones"
  add_foreign_key "cooperacion_condonados", "cooperaciones"
  add_foreign_key "cooperacion_condonados", "trabajadores"
  add_foreign_key "cooperacion_detalles_confirmados", "cooperaciones"
  add_foreign_key "cooperacion_detalles_confirmados", "trabajadores", on_delete: :nullify
  add_foreign_key "cooperaciones", "cuentas_financieras", column: "cuenta_financiera_id"
  add_foreign_key "cooperaciones", "usuarios", column: "confirmada_por_id"
  add_foreign_key "egresos", "cuentas_financieras", column: "cuenta_financiera_id"
  add_foreign_key "evento_asistencias", "eventos"
  add_foreign_key "evento_asistencias", "trabajadores"
  add_foreign_key "eventos", "usuarios", column: "confirmado_por_id"
  add_foreign_key "historiales", "usuarios", on_delete: :nullify
  add_foreign_key "trabajadores", "concepto07_niveles"
  add_foreign_key "usuarios", "cuentas_financieras", column: "cuenta_financiera_id"
  add_foreign_key "usuarios", "trabajadores", on_delete: :restrict
end

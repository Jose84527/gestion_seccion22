# Seeds para entorno de desarrollo / demostración.
# Deja la base limpia con un único usuario administrador inicial.

puts "Creando usuario administrador inicial..."

admin = Usuario.find_or_initialize_by(nombre_usuario: "admin")

admin.password = "admin123"
admin.password_confirmation = "admin123"
admin.rol_sistema = "admin"
admin.activo = true
admin.trabajador_id = nil
admin.ultimo_acceso_at = nil

# Se saltan validaciones porque el modelo Usuario exige trabajador en creación,
# pero para la cuenta inicial de administración necesitamos permitir admin sin trabajador.
admin.save!(validate: false)

puts "Usuario administrador listo:"
puts "  usuario: admin"
puts "  contraseña: admin123"

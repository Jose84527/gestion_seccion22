module Autorizacion
  class Permisos
    MATRIZ = {
      admin: {
        dashboard: :all,
        trabajadores: :all,
        cooperaciones: :all,
        eventos: :all,
        usuarios: :all,
        historial: :all
      },
      finanzas: {
        trabajadores: %i[ver],
        cooperaciones: %i[ver crear registrar_pago exentar]
      }
    }.freeze

    class << self
      def puede_ver_modulo?(usuario, modulo)
        puede?(usuario, modulo, :ver)
      end

      def puede?(usuario, modulo, accion = :ver)
        return false if usuario.blank?
        return false if usuario.rol_sistema.blank?

        rol = usuario.rol_sistema.to_sym
        permisos_rol = MATRIZ[rol]
        return false if permisos_rol.blank?

        permisos_modulo = permisos_rol[modulo.to_sym]
        return false if permisos_modulo.blank?

        permisos_modulo == :all || permisos_modulo.include?(accion.to_sym)
      end

      def modulos_visibles(usuario)
        return [] if usuario.blank?
        return [] if usuario.rol_sistema.blank?

        MATRIZ.fetch(usuario.rol_sistema.to_sym, {}).keys
      end
    end
  end
end
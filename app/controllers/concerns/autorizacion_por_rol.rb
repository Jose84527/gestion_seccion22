module AutorizacionPorRol
  extend ActiveSupport::Concern

  included do
    helper_method :puede_ver_modulo?, :puede_realizar_accion?
  end

  private

  def puede_ver_modulo?(modulo)
    Autorizacion::Permisos.puede_ver_modulo?(usuario_actual, modulo)
  end

  def puede_realizar_accion?(modulo, accion)
    Autorizacion::Permisos.puede?(usuario_actual, modulo, accion)
  end

  def requiere_permiso!(modulo, accion = :ver)
    unless sesion_iniciada?
      redirect_to login_path, alert: "Debes iniciar sesión para continuar"
      return
    end

    return if puede_realizar_accion?(modulo, accion)

    redirect_to menu_path, alert: "No tienes permiso para acceder a esta sección"
  end
end
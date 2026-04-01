class ApplicationController < ActionController::Base
  include AutorizacionPorRol

  before_action :establecer_usuario_actual

  helper_method :usuario_actual, :sesion_iniciada?

  private

  def establecer_usuario_actual
    Current.usuario = nil
    return unless session[:usuario_id].present?

    Current.usuario = Usuario.find_by(id: session[:usuario_id])
  end

  def usuario_actual
    Current.usuario
  end

  def sesion_iniciada?
    usuario_actual.present?
  end

  def autenticar_usuario
    return if sesion_iniciada?

    redirect_to login_path, alert: "Debes iniciar sesión para continuar"
  end
end
class ApplicationController < ActionController::Base
  include AutorizacionPorRol
  helper NavigationHelper

  before_action :establecer_usuario_actual

  helper_method :usuario_actual,
                :sesion_iniciada?,
                :admin_actual?,
                :finanzas_actual?,
                :cuenta_financiera_contexto,
                :cuentas_financieras_disponibles

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

  def admin_actual?
    usuario_actual&.admin?
  end

  def finanzas_actual?
    usuario_actual&.finanzas?
  end

  def autenticar_usuario
    return if sesion_iniciada?

    redirect_to login_path, alert: "Debes iniciar sesión para continuar"
  end

  def requiere_cuenta_financiera_para_finanzas!
    return unless finanzas_actual?
    return if usuario_actual.cuenta_financiera.present?

    redirect_to menu_path,
                alert: "Tu usuario de finanzas no tiene una cuenta financiera asignada. Contacta al administrador."
  end

  def cuentas_financieras_disponibles
    if admin_actual?
      CuentaFinanciera.activas
    elsif finanzas_actual? && usuario_actual.cuenta_financiera_id.present?
      CuentaFinanciera.where(id: usuario_actual.cuenta_financiera_id)
    else
      CuentaFinanciera.none
    end
  end

  def cuenta_financiera_contexto
    @cuenta_financiera_contexto ||= begin
      if admin_actual?
        cuenta_id = params[:cuenta_financiera_id].to_s.strip

        cuenta_id.present? ? CuentaFinanciera.find_by(id: cuenta_id) : nil
      elsif finanzas_actual?
        usuario_actual.cuenta_financiera
      end
    end
  end

  def aplicar_cuenta_financiera(scope)
    return scope unless scope.klass.column_names.include?("cuenta_financiera_id")

    if finanzas_actual?
      return scope.none if usuario_actual.cuenta_financiera.blank?

      scope.where(cuenta_financiera_id: usuario_actual.cuenta_financiera_id)
    elsif admin_actual? && cuenta_financiera_contexto.present?
      scope.where(cuenta_financiera_id: cuenta_financiera_contexto.id)
    else
      scope
    end
  end

  def asignar_cuenta_financiera_a_registro(registro, parametros = nil)
    return unless registro.respond_to?(:cuenta_financiera=)

    cuenta = if finanzas_actual?
               usuario_actual.cuenta_financiera
             elsif admin_actual?
               cuenta_id = extraer_cuenta_financiera_id(parametros)

               if cuenta_id.present?
                 CuentaFinanciera.find_by(id: cuenta_id)
               else
                 CuentaFinanciera.activas.first
               end
             end

    registro.cuenta_financiera = cuenta
  end

  def extraer_cuenta_financiera_id(parametros)
    if parametros.respond_to?(:[])
      parametros[:cuenta_financiera_id].to_s.strip.presence
    else
      params[:cuenta_financiera_id].to_s.strip.presence
    end
  end
end
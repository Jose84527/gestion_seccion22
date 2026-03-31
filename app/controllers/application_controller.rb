class ApplicationController < ActionController::Base
  helper_method :usuario_actual

  def usuario_actual
    @usuario_actual ||= Usuario.find(session[:usuario_id]) if session[:usuario_id]
  end

  def autenticar_usuario
    redirect_to login_path unless usuario_actual
  end
end
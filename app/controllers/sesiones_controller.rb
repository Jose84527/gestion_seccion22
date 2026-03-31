class SesionesController < ApplicationController
  def new
    redirect_to menu_path if sesion_iniciada?
  end

  def create
    nombre_usuario = params[:nombre_usuario].to_s.strip.downcase
    password = params[:password].to_s

    usuario = Usuario.find_by(nombre_usuario: nombre_usuario)

    if usuario&.activo? && usuario.authenticate(password)
      reset_session
      session[:usuario_id] = usuario.id
      usuario.update_column(:ultimo_acceso_at, Time.current)

      redirect_to menu_path, notice: "Bienvenido #{usuario.nombre_usuario}"
    else
      flash.now[:alert] = "Usuario o contraseña incorrectos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sesión cerrada correctamente"
  end
end
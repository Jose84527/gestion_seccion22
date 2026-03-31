class SesionesController < ApplicationController
  def new
  end

  def create
    usuario = Usuario.find_by(nombre_usuario: params[:nombre_usuario])

    if usuario && usuario.authenticate(params[:password])
      session[:usuario_id] = usuario.id
      redirect_to menu_path, notice: "Bienvenido #{usuario.nombre_usuario}"
    else
      flash.now[:alert] = "Usuario o contraseña incorrectos"
      render :new
    end
  end

  def destroy
    session[:usuario_id] = nil
    redirect_to root_path, notice: "Sesión cerrada"
  end
end
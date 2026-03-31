class SessionsController < ApplicationController
  def new
  end

  def create
    usuario = Usuario.find_by(username: params[:username])

    if usuario && usuario.authenticate(params[:password])
      session[:usuario_id] = usuario.id
      redirect_to dashboard_path # o root_path
    else
      flash.now[:alert] = "❌ Usuario o contraseña incorrectos"
      render :new, status: :unprocessable_entity
    end
  end
end
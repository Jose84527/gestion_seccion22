class SesionesController < ApplicationController
  def new
    if sesion_iniciada?
      return redirect_to(ruta_inicial_para(usuario_actual))
    end
  end

  def create
    nombre_usuario = params[:nombre_usuario].to_s.strip.downcase
    password = params[:password].to_s

    if nombre_usuario.blank?
      flash.now[:alert] = "Falta el nombre de usuario"
      return render :new, status: :unprocessable_entity
    end

    if password.blank?
      flash.now[:alert] = "Falta la contraseña"
      return render :new, status: :unprocessable_entity
    end

    usuario = Usuario.find_by(nombre_usuario: nombre_usuario)

    if usuario&.activo? && usuario.authenticate(password)
      reset_session
      session[:usuario_id] = usuario.id
      usuario.update_column(:ultimo_acceso_at, Time.current)

      redirect_to ruta_inicial_para(usuario), notice: "Bienvenido #{usuario.nombre_usuario}"
    else
      flash.now[:alert] = "Usuario o contraseña incorrectos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sesión cerrada correctamente"
  end

  private

  def ruta_inicial_para(usuario)
    return menu_path if usuario&.admin?

    root_path
  end
end
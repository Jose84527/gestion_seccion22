class UsuariosController < ApplicationController
  before_action :autenticar_usuario
  before_action -> { requiere_permiso!(:usuarios, :ver) }, only: %i[index]
  before_action -> { requiere_permiso!(:usuarios, :crear) }, only: %i[new create buscar_trabajadores]
  before_action -> { requiere_permiso!(:usuarios, :editar) }, only: %i[edit update]
  before_action :set_usuario, only: %i[edit update]

  def index
    @usuarios = Usuario.includes(:trabajador).order(:nombre_usuario)
  end

  def new
    @usuario = Usuario.new(
      activo: true,
      rol_sistema: "finanzas"
    )
  end

  def create
    @usuario = Usuario.new(usuario_params_para_crear)

    if @usuario.save
      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "crear",
        modulo: "usuarios",
        entidad: "Usuario",
        registro_id: @usuario.id,
        resumen: resumen_creacion(@usuario),
        antes: nil,
        despues: @usuario.snapshot_para_historial,
        request: request
      )

      redirect_to usuarios_path, notice: "Usuario creado correctamente"
    else
      flash.now[:alert] = "No se pudo crear el usuario"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    snapshot_antes = @usuario.snapshot_para_historial
    cambio_password = usuario_params_para_actualizar[:password].present?

    if @usuario.update(usuario_params_para_actualizar)
      snapshot_despues = @usuario.snapshot_para_historial

      if snapshot_antes != snapshot_despues || cambio_password
        Historiales::Registrador.registrar!(
          usuario: usuario_actual,
          accion: "editar",
          modulo: "usuarios",
          entidad: "Usuario",
          registro_id: @usuario.id,
          resumen: resumen_actualizacion(@usuario, snapshot_antes, snapshot_despues, cambio_password),
          antes: snapshot_antes,
          despues: snapshot_despues,
          request: request
        )
      end

      redirect_to usuarios_path, notice: "Usuario actualizado correctamente"
    else
      flash.now[:alert] = "No se pudo actualizar el usuario"
      render :edit, status: :unprocessable_entity
    end
  end

  def buscar_trabajadores
    termino = params[:q].to_s.strip

    return render json: [] if termino.length < 2

    trabajadores = Trabajador.left_outer_joins(:usuario)
                             .where(usuarios: { id: nil })
                             .where(
                               "nombres ILIKE :q OR apellido_paterno ILIKE :q OR apellido_materno ILIKE :q OR rfc ILIKE :q OR clave_cobro ILIKE :q",
                               q: "%#{termino}%"
                             )
                             .ordenados
                             .limit(10)

    render json: trabajadores.map { |trabajador|
      {
        id: trabajador.id,
        nombre: trabajador.nombre_completo,
        rfc: trabajador.rfc,
        clave_cobro: trabajador.clave_cobro,
        etiqueta: "#{trabajador.nombre_completo} · #{trabajador.rfc} · #{trabajador.clave_cobro}"
      }
    }
  end

  private

  def set_usuario
    @usuario = Usuario.find(params[:id])
  end

  def usuario_params_para_crear
    params.require(:usuario).permit(
      :trabajador_id,
      :nombre_usuario,
      :rol_sistema,
      :activo,
      :password,
      :password_confirmation
    )
  end

  def usuario_params_para_actualizar
    permitidos = params.require(:usuario).permit(
      :nombre_usuario,
      :rol_sistema,
      :activo,
      :password,
      :password_confirmation
    )

    if permitidos[:password].blank? && permitidos[:password_confirmation].blank?
      permitidos.except(:password, :password_confirmation)
    else
      permitidos
    end
  end

  def resumen_creacion(usuario)
    if usuario.trabajador.present?
      "Se creó el usuario #{usuario.nombre_usuario} para #{usuario.trabajador.nombre_completo}"
    else
      "Se creó el usuario #{usuario.nombre_usuario}"
    end
  end

  def resumen_actualizacion(usuario, antes, despues, cambio_password)
    cambios = []

    cambios << "nombre de usuario" if antes[:nombre_usuario] != despues[:nombre_usuario]
    cambios << "rol" if antes[:rol_sistema] != despues[:rol_sistema]
    cambios << "estado de la cuenta" if antes[:activo] != despues[:activo]
    cambios << "trabajador asociado" if antes[:trabajador_id] != despues[:trabajador_id]
    cambios << "contraseña" if cambio_password

    if cambios.empty?
      "Se actualizó el usuario #{usuario.nombre_usuario}"
    elsif cambios.length == 1
      "Se actualizó #{cambios.first} del usuario #{usuario.nombre_usuario}"
    else
      "Se actualizaron #{lista_humana(cambios)} del usuario #{usuario.nombre_usuario}"
    end
  end

  def lista_humana(items)
    return items.first if items.length == 1
    return "#{items.first} y #{items.last}" if items.length == 2

    "#{items[0..-2].join(', ')} y #{items.last}"
  end
end
class TrabajadoresController < ApplicationController
  TRABAJADORES_POR_PAGINA = 20

  before_action :autenticar_usuario
  before_action -> { requiere_permiso!(:trabajadores, :ver) }, only: %i[index show]
  before_action -> { requiere_permiso!(:trabajadores, :crear) }, only: %i[new create]
  before_action -> { requiere_permiso!(:trabajadores, :editar) }, only: %i[edit update cambiar_estado]
  before_action :set_trabajador, only: %i[show edit update cambiar_estado]
  before_action :cargar_catalogos, only: %i[index new create edit update]

  def index
    @q = params[:q].to_s.strip
    @concepto07_nivel_id = params[:concepto07_nivel_id].to_s
    @estado_trabajador = params[:estado_trabajador].to_s

    base = Trabajador.includes(:concepto07_nivel)
                     .buscar_por_nombre(@q)
                     .filtrar_por_concepto07(@concepto07_nivel_id)
                     .filtrar_por_estado(@estado_trabajador)
                     .ordenados

    @total_registros = base.count
    @total_paginas = (@total_registros.to_f / TRABAJADORES_POR_PAGINA).ceil
    @total_paginas = 1 if @total_paginas.zero?

    @pagina_actual = params[:page].to_i
    @pagina_actual = 1 if @pagina_actual < 1
    @pagina_actual = @total_paginas if @pagina_actual > @total_paginas

    offset = (@pagina_actual - 1) * TRABAJADORES_POR_PAGINA

    @trabajadores = base.offset(offset).limit(TRABAJADORES_POR_PAGINA)
  end

  def show
  end

  def new
    @trabajador = Trabajador.new(
      fecha_afiliacion: Date.current,
      estado_trabajador: "activo"
    )
  end

  def create
    @trabajador = Trabajador.new(trabajador_params)

    if @trabajador.save
      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "crear",
        modulo: "trabajadores",
        entidad: "Trabajador",
        registro_id: @trabajador.id,
        resumen: "Se creó el trabajador #{@trabajador.nombre_completo}",
        antes: nil,
        despues: @trabajador.snapshot_para_historial,
        request: request
      )

      redirect_to trabajador_path(@trabajador), notice: "Trabajador creado correctamente"
    else
      flash.now[:alert] = "No se pudo crear el trabajador"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    snapshot_antes = @trabajador.snapshot_para_historial

    if @trabajador.update(trabajador_params)
      snapshot_despues = @trabajador.snapshot_para_historial

      if snapshot_antes != snapshot_despues
        Historiales::Registrador.registrar!(
          usuario: usuario_actual,
          accion: "editar",
          modulo: "trabajadores",
          entidad: "Trabajador",
          registro_id: @trabajador.id,
          resumen: "Se actualizó el trabajador #{@trabajador.nombre_completo}",
          antes: snapshot_antes,
          despues: snapshot_despues,
          request: request
        )
      end

      redirect_to trabajador_path(@trabajador), notice: "Trabajador actualizado correctamente"
    else
      flash.now[:alert] = "No se pudo actualizar el trabajador"
      render :edit, status: :unprocessable_entity
    end
  end

  def cambiar_estado
    nuevo_estado = estado_trabajador_params[:estado_trabajador]

    unless Trabajador.estado_trabajadores.key?(nuevo_estado)
      return redirect_to trabajador_path(@trabajador), alert: "El estado seleccionado no es válido"
    end

    estado_anterior = @trabajador.estado_trabajador

    if estado_anterior == nuevo_estado
      return redirect_to trabajador_path(@trabajador),
                         notice: "El trabajador ya se encuentra en estado #{estado_anterior.humanize}"
    end

    snapshot_antes = @trabajador.snapshot_para_historial

    if @trabajador.update(estado_trabajador: nuevo_estado)
      snapshot_despues = @trabajador.snapshot_para_historial

      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "trabajadores",
        entidad: "Trabajador",
        registro_id: @trabajador.id,
        resumen: "Se cambió el estado del trabajador #{@trabajador.nombre_completo} de #{estado_anterior.humanize} a #{@trabajador.estado_trabajador.humanize}",
        antes: snapshot_antes,
        despues: snapshot_despues,
        request: request
      )

      redirect_to trabajador_path(@trabajador),
                  notice: "Estado actualizado de #{estado_anterior.humanize} a #{@trabajador.estado_trabajador.humanize}"
    else
      redirect_to trabajador_path(@trabajador), alert: @trabajador.errors.full_messages.to_sentence
    end
  end

  private

  def set_trabajador
    @trabajador = Trabajador.find(params[:id])
  end

  def cargar_catalogos
    @conceptos07 = Concepto07Nivel.activos
  end

  def trabajador_params
    params.require(:trabajador).permit(
      :nombres,
      :apellido_paterno,
      :apellido_materno,
      :sexo,
      :fecha_afiliacion,
      :rfc,
      :curp,
      :clave_cobro,
      :ct,
      :telefono,
      :correo,
      :direccion,
      :codigo_postal,
      :estado_trabajador,
      :salario_neto,
      :periodicidad_pago,
      :concepto07_nivel_id
    )
  end

  def estado_trabajador_params
    params.require(:trabajador).permit(:estado_trabajador)
  end
end
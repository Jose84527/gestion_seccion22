class TrabajadoresController < ApplicationController
  TRABAJADORES_POR_PAGINA = 20

  before_action :autenticar_usuario
  before_action -> { requiere_permiso!(:trabajadores, :ver) }, only: %i[index show]
  before_action -> { requiere_permiso!(:trabajadores, :crear) }, only: %i[new create]
  before_action -> { requiere_permiso!(:trabajadores, :editar) }, only: %i[edit update]
  before_action :set_trabajador, only: %i[show edit update]
  before_action :cargar_catalogos, only: %i[index new create edit update]

  def index
    @q = params[:q].to_s.strip
    @concepto07_nivel_id = params[:concepto07_nivel_id].to_s
    @estado_trabajador = params[:estado_trabajador].to_s
    @sexo = params[:sexo].to_s
    @tipo_trabajador = params[:tipo_trabajador].to_s

    base = Trabajador.includes(:concepto07_nivel)
                     .buscar_por_texto(@q)
                     .filtrar_por_concepto07(@concepto07_nivel_id)
                     .filtrar_por_estado(@estado_trabajador)
                     .filtrar_por_sexo(@sexo)
                     .filtrar_por_tipo_trabajador(@tipo_trabajador)
                     .ordenados

    @total_registros = base.count
    @total_paginas = (@total_registros.to_f / TRABAJADORES_POR_PAGINA).ceil
    @total_paginas = 1 if @total_paginas.zero?

    @pagina_actual = params[:page].to_i
    @pagina_actual = 1 if @pagina_actual < 1
    @pagina_actual = @total_paginas if @pagina_actual > @total_paginas

    offset = (@pagina_actual - 1) * TRABAJADORES_POR_PAGINA

    @trabajadores = base
                    .offset(offset)
                    .limit(TRABAJADORES_POR_PAGINA)
  end

  def show
  end

  def new
    @trabajador = Trabajador.new(
      fecha_ingreso: Date.current
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

  private

  def set_trabajador
    @trabajador = Trabajador.find(params[:id])
  end

  def cargar_catalogos
    ids = Concepto07Nivel.activos.pluck(:id)
    ids << @trabajador.concepto07_nivel_id if defined?(@trabajador) && @trabajador&.concepto07_nivel_id.present?

    @categorias = Concepto07Nivel.where(id: ids.uniq).order(:nombre)
  end

  def trabajador_params
    params.require(:trabajador).permit(
      :nombres,
      :apellido_paterno,
      :apellido_materno,
      :sexo,
      :tipo_trabajador,
      :fecha_ingreso,
      :rfc,
      :curp,
      :clave_cobro,
      :ct,
      :telefono,
      :correo,
      :direccion,
      :codigo_postal,
      :estado_trabajador,
      :concepto07_nivel_id,
      :condonado_habitual
    )
  end
end
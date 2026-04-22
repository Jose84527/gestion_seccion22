class CooperacionesController < ApplicationController
  before_action :autenticar_usuario
  before_action -> { requiere_permiso!(:cooperaciones, :ver) }, only: %i[index show]
  before_action -> { requiere_permiso!(:cooperaciones, :crear) }, only: %i[new create]
  before_action -> { requiere_permiso!(:cooperaciones, :editar) }, only: %i[edit update cambiar_estado]
  before_action :set_cooperacion, only: %i[show edit update cambiar_estado]

  def index
    @cooperaciones = Cooperacion.order(:nombre)
  end

  def show
  end

  def new
    @cooperacion = Cooperacion.new(
      activa: true,
      es_recurrente: false,
      periodicidad_generacion: "mensual"
    )
  end

  def create
    @cooperacion = Cooperacion.new(cooperacion_params)

    if @cooperacion.save
      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "crear",
        modulo: "cooperaciones",
        entidad: "Cooperacion",
        registro_id: @cooperacion.id,
        resumen: "Se creó la cooperación #{@cooperacion.nombre}",
        antes: nil,
        despues: @cooperacion.snapshot_para_historial,
        request: request
      )

      redirect_to cooperacion_path(@cooperacion), notice: "Cooperación creada correctamente"
    else
      flash.now[:alert] = "No se pudo crear la cooperación"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    snapshot_antes = @cooperacion.snapshot_para_historial

    if @cooperacion.update(cooperacion_params)
      snapshot_despues = @cooperacion.snapshot_para_historial

      if snapshot_antes != snapshot_despues
        Historiales::Registrador.registrar!(
          usuario: usuario_actual,
          accion: "editar",
          modulo: "cooperaciones",
          entidad: "Cooperacion",
          registro_id: @cooperacion.id,
          resumen: "Se actualizó la cooperación #{@cooperacion.nombre}",
          antes: snapshot_antes,
          despues: snapshot_despues,
          request: request
        )
      end

      redirect_to cooperacion_path(@cooperacion), notice: "Cooperación actualizada correctamente"
    else
      flash.now[:alert] = "No se pudo actualizar la cooperación"
      render :edit, status: :unprocessable_entity
    end
  end

  def cambiar_estado
    snapshot_antes = @cooperacion.snapshot_para_historial
    nuevo_estado = !@cooperacion.activa?

    if @cooperacion.update(activa: nuevo_estado)
      snapshot_despues = @cooperacion.snapshot_para_historial

      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "cooperaciones",
        entidad: "Cooperacion",
        registro_id: @cooperacion.id,
        resumen: nuevo_estado ? "Se activó la cooperación #{@cooperacion.nombre}" : "Se desactivó la cooperación #{@cooperacion.nombre}",
        antes: snapshot_antes,
        despues: snapshot_despues,
        request: request
      )

      redirect_to cooperaciones_path,
                  notice: nuevo_estado ? "Cooperación activada correctamente" : "Cooperación desactivada correctamente"
    else
      redirect_to cooperaciones_path, alert: "No se pudo cambiar el estado de la cooperación"
    end
  end

  private

  def set_cooperacion
    @cooperacion = Cooperacion.find(params[:id])
  end

  def cooperacion_params
    params.require(:cooperacion).permit(
      :nombre,
      :descripcion,
      :tipo_cooperacion,
      :monto_fijo_base,
      :es_recurrente,
      :periodicidad_generacion,
      :fecha_inicio_vigencia,
      :fecha_fin_vigencia,
      :activa
    )
  end
end
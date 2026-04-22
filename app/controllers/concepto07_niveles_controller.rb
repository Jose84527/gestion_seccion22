class Concepto07NivelesController < ApplicationController
  before_action :autenticar_usuario
  before_action -> { requiere_permiso!(:conceptos07, :ver) }, only: %i[index]
  before_action -> { requiere_permiso!(:conceptos07, :crear) }, only: %i[new create]
  before_action -> { requiere_permiso!(:conceptos07, :editar) }, only: %i[edit update cambiar_estado]
  before_action :set_concepto07_nivel, only: %i[edit update cambiar_estado]

  def index
    @conceptos07 = Concepto07Nivel.order(:clave)
  end

  def new
    @concepto07_nivel = Concepto07Nivel.new(activo: true)
  end

  def create
    @concepto07_nivel = Concepto07Nivel.new(concepto07_nivel_params.merge(activo: true))

    if @concepto07_nivel.save
      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "crear",
        modulo: "categorias",
        entidad: "Concepto07Nivel",
        registro_id: @concepto07_nivel.id,
        resumen: "Se creó la categoría #{@concepto07_nivel.nombre} con clave #{@concepto07_nivel.clave}",
        antes: nil,
        despues: @concepto07_nivel.snapshot_para_historial,
        request: request
      )

      redirect_to concepto07_niveles_path, notice: "Categoría creada correctamente"
    else
      flash.now[:alert] = "No se pudo crear la categoría"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    snapshot_antes = @concepto07_nivel.snapshot_para_historial

    if @concepto07_nivel.update(concepto07_nivel_params)
      snapshot_despues = @concepto07_nivel.snapshot_para_historial

      if snapshot_antes != snapshot_despues
        Historiales::Registrador.registrar!(
          usuario: usuario_actual,
          accion: "editar",
          modulo: "categorias",
          entidad: "Concepto07Nivel",
          registro_id: @concepto07_nivel.id,
          resumen: "Se actualizó la categoría #{@concepto07_nivel.nombre}",
          antes: snapshot_antes,
          despues: snapshot_despues,
          request: request
        )
      end

      redirect_to concepto07_niveles_path, notice: "Categoría actualizada correctamente"
    else
      flash.now[:alert] = "No se pudo actualizar la categoría"
      render :edit, status: :unprocessable_entity
    end
  end

  def cambiar_estado
    estado_anterior = @concepto07_nivel.activo?
    snapshot_antes = @concepto07_nivel.snapshot_para_historial
    nuevo_estado = !estado_anterior

    if @concepto07_nivel.update(activo: nuevo_estado)
      snapshot_despues = @concepto07_nivel.snapshot_para_historial

      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "categorias",
        entidad: "Concepto07Nivel",
        registro_id: @concepto07_nivel.id,
        resumen: "Se cambió el estado de la categoría #{@concepto07_nivel.nombre} de #{estado_anterior ? 'activo' : 'inactivo'} a #{@concepto07_nivel.activo? ? 'activo' : 'inactivo'}",
        antes: snapshot_antes,
        despues: snapshot_despues,
        request: request
      )

      mensaje = nuevo_estado ? "Categoría activada correctamente" : "Categoría desactivada correctamente"
      redirect_to concepto07_niveles_path, notice: mensaje
    else
      redirect_to concepto07_niveles_path, alert: "No se pudo cambiar el estado de la categoría"
    end
  end

  private

  def set_concepto07_nivel
    @concepto07_nivel = Concepto07Nivel.find(params[:id])
  end

  def concepto07_nivel_params
    params.require(:concepto07_nivel).permit(:nombre, :monto_concepto07)
  end
end
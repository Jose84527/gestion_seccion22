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
    @concepto07_nivel = Concepto07Nivel.new(concepto07_nivel_params)

    if @concepto07_nivel.save
      redirect_to concepto07_niveles_path, notice: "Concepto 07 creado correctamente"
    else
      flash.now[:alert] = "No se pudo crear el concepto 07"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @concepto07_nivel.update(concepto07_nivel_params)
      redirect_to concepto07_niveles_path, notice: "Concepto 07 actualizado correctamente"
    else
      flash.now[:alert] = "No se pudo actualizar el concepto 07"
      render :edit, status: :unprocessable_entity
    end
  end

  def cambiar_estado
    nuevo_estado = !@concepto07_nivel.activo?

    if @concepto07_nivel.update(activo: nuevo_estado)
      mensaje = nuevo_estado ? "Concepto 07 activado correctamente" : "Concepto 07 desactivado correctamente"
      redirect_to concepto07_niveles_path, notice: mensaje
    else
      redirect_to concepto07_niveles_path, alert: "No se pudo cambiar el estado del concepto 07"
    end
  end

  private

  def set_concepto07_nivel
    @concepto07_nivel = Concepto07Nivel.find(params[:id])
  end

  def concepto07_nivel_params
    params.require(:concepto07_nivel).permit(:clave, :nombre, :descripcion, :activo)
  end
end
class TrabajadoresController < ApplicationController
  before_action :autenticar_usuario
  before_action -> { requiere_permiso!(:trabajadores, :ver) }, only: %i[index show]
  before_action -> { requiere_permiso!(:trabajadores, :crear) }, only: %i[new create]
  before_action -> { requiere_permiso!(:trabajadores, :editar) }, only: %i[edit update]
  before_action :set_trabajador, only: %i[show edit update]
  before_action :cargar_catalogos, only: %i[new create edit update]

  def index
    @trabajadores = Trabajador.includes(:concepto07_nivel).order(:apellido_paterno, :apellido_materno, :nombres)
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
      redirect_to trabajador_path(@trabajador), notice: "Trabajador creado correctamente"
    else
      flash.now[:alert] = "No se pudo crear el trabajador"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @trabajador.update(trabajador_params)
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
end
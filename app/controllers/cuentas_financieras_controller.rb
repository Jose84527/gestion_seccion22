class CuentasFinancierasController < ApplicationController
  before_action :autenticar_usuario
  before_action -> { requiere_permiso!(:cuentas_financieras, :ver) }, only: %i[index]
  before_action -> { requiere_permiso!(:cuentas_financieras, :crear) }, only: %i[new create]
  before_action -> { requiere_permiso!(:cuentas_financieras, :editar) }, only: %i[edit update cambiar_estado]
  before_action :set_cuenta_financiera, only: %i[edit update cambiar_estado]

  def index
    @cuentas_financieras = CuentaFinanciera.ordenadas
  end

  def new
    @cuenta_financiera = CuentaFinanciera.new(activa: true)
  end

  def create
    @cuenta_financiera = CuentaFinanciera.new(cuenta_financiera_params)

    if @cuenta_financiera.save
      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "crear",
        modulo: "cuentas_financieras",
        entidad: "CuentaFinanciera",
        registro_id: @cuenta_financiera.id,
        resumen: "Se creó la cuenta financiera #{@cuenta_financiera.nombre}",
        antes: nil,
        despues: @cuenta_financiera.snapshot_para_historial,
        request: request
      )

      redirect_to cuenta_financieras_path, notice: "Cuenta financiera creada correctamente"
    else
      flash.now[:alert] = "No se pudo crear la cuenta financiera"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    snapshot_antes = @cuenta_financiera.snapshot_para_historial

    if @cuenta_financiera.update(cuenta_financiera_params)
      snapshot_despues = @cuenta_financiera.snapshot_para_historial

      if snapshot_antes != snapshot_despues
        Historiales::Registrador.registrar!(
          usuario: usuario_actual,
          accion: "editar",
          modulo: "cuentas_financieras",
          entidad: "CuentaFinanciera",
          registro_id: @cuenta_financiera.id,
          resumen: "Se actualizó la cuenta financiera #{@cuenta_financiera.nombre}",
          antes: snapshot_antes,
          despues: snapshot_despues,
          request: request
        )
      end

      redirect_to cuenta_financieras_path, notice: "Cuenta financiera actualizada correctamente"
    else
      flash.now[:alert] = "No se pudo actualizar la cuenta financiera"
      render :edit, status: :unprocessable_entity
    end
  end

  def cambiar_estado
    snapshot_antes = @cuenta_financiera.snapshot_para_historial
    nuevo_estado = !@cuenta_financiera.activa?

    if @cuenta_financiera.update(activa: nuevo_estado)
      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "cuentas_financieras",
        entidad: "CuentaFinanciera",
        registro_id: @cuenta_financiera.id,
        resumen: "Se #{@cuenta_financiera.activa? ? 'activó' : 'desactivó'} la cuenta financiera #{@cuenta_financiera.nombre}",
        antes: snapshot_antes,
        despues: @cuenta_financiera.snapshot_para_historial,
        request: request
      )

      redirect_to cuenta_financieras_path,
                  notice: @cuenta_financiera.activa? ? "Cuenta financiera activada correctamente" : "Cuenta financiera desactivada correctamente"
    else
      redirect_to cuenta_financieras_path, alert: "No se pudo cambiar el estado de la cuenta financiera"
    end
  end

  private

  def set_cuenta_financiera
    @cuenta_financiera = CuentaFinanciera.find(params[:id])
  end

  def cuenta_financiera_params
    params.require(:cuenta_financiera).permit(
      :nombre,
      :responsable_nombre,
      :responsable_puesto,
      :activa
    )
  end
end
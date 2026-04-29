class CooperacionesController < ApplicationController
  before_action :autenticar_usuario
  before_action -> { requiere_permiso!(:cooperaciones, :ver) },
                only: %i[index show buscar_trabajadores pdf_lista_general pdf_recibos]
  before_action -> { requiere_permiso!(:cooperaciones, :crear) }, only: %i[new create]
  before_action -> { requiere_permiso!(:cooperaciones, :editar) }, only: %i[edit update cambiar_estado]
  before_action :set_cooperacion, only: %i[show edit update cambiar_estado pdf_lista_general pdf_recibos]

  def index
    @cooperaciones = Cooperacion.includes(:cooperacion_conceptos, :cooperacion_condonados).recientes
  end

  def show
    @desglose_trabajadores = @cooperacion.desglose_por_trabajador
    @total_esperado = @desglose_trabajadores.sum { |fila| fila[:total].to_d }
  end

  def new
    @cooperacion = Cooperacion.new(
      estado: "activa",
      fecha_inicio_vigencia: Date.current
    )

    @cooperacion.cooperacion_conceptos.build(
      tipo_cooperacion: "fija",
      posicion: 1
    )
  end

  def create
    @cooperacion = Cooperacion.new(cooperacion_params)
    @cooperacion.estado = "activa"

    if @cooperacion.save
      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "crear",
        modulo: "cooperaciones",
        entidad: "Cooperacion",
        registro_id: @cooperacion.id,
        resumen: "Se creó la corrida de cooperación #{@cooperacion.nombre}",
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
    preparar_edicion
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
          resumen: "Se actualizó la corrida de cooperación #{@cooperacion.nombre}",
          antes: snapshot_antes,
          despues: snapshot_despues,
          request: request
        )
      end

      redirect_to cooperacion_path(@cooperacion), notice: "Cooperación actualizada correctamente"
    else
      flash.now[:alert] = "No se pudo actualizar la cooperación"
      preparar_edicion
      render :edit, status: :unprocessable_entity
    end
  end

  def cambiar_estado
    if @cooperacion.completada?
      return redirect_to cooperaciones_path,
                         alert: "No se puede cambiar el estado de una cooperación completada"
    end

    snapshot_antes = @cooperacion.snapshot_para_historial
    nuevo_estado = @cooperacion.activa? ? "cancelada" : "activa"

    if @cooperacion.update(estado: nuevo_estado)
      snapshot_despues = @cooperacion.snapshot_para_historial

      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "cooperaciones",
        entidad: "Cooperacion",
        registro_id: @cooperacion.id,
        resumen: "Se cambió el estado de la cooperación #{@cooperacion.nombre} a #{nuevo_estado}",
        antes: snapshot_antes,
        despues: snapshot_despues,
        request: request
      )

      redirect_to cooperaciones_path,
                  notice: nuevo_estado == "activa" ? "Cooperación reactivada correctamente" : "Cooperación cancelada correctamente"
    else
      redirect_to cooperaciones_path, alert: "No se pudo cambiar el estado de la cooperación"
    end
  end

  def pdf_lista_general
    pdf = Pdf::CooperacionListaGeneralPdf.new(@cooperacion).render

    send_data pdf,
              filename: "lista_general_cooperacion_#{@cooperacion.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  def pdf_recibos
    pdf = Pdf::CooperacionRecibosPdf.new(@cooperacion).render

    send_data pdf,
              filename: "recibos_cooperacion_#{@cooperacion.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  def buscar_trabajadores
    termino = params[:q].to_s.strip

    return render json: [] if termino.length < 2

    trabajadores = Trabajador.includes(:concepto07_nivel)
                             .where(estado_trabajador: "activo")
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
        tipo_trabajador: trabajador.tipo_trabajador&.humanize,
        etiqueta: "#{trabajador.nombre_completo} · #{trabajador.rfc} · #{trabajador.clave_cobro}"
      }
    }
  end

  private

  def set_cooperacion
    @cooperacion = Cooperacion.find(params[:id])
  end

  def preparar_edicion
    return if @cooperacion.cooperacion_conceptos.any?

    @cooperacion.cooperacion_conceptos.build(
      tipo_cooperacion: "fija",
      posicion: 1
    )
  end

  def cooperacion_params
    params.require(:cooperacion).permit(
      :nombre,
      :fecha_inicio_vigencia,
      :fecha_fin_vigencia,
      cooperacion_conceptos_attributes: [
        :id,
        :nombre,
        :descripcion,
        :tipo_cooperacion,
        :monto_fijo,
        :porcentaje,
        :posicion,
        :_destroy
      ],
      cooperacion_condonados_attributes: [
        :id,
        :trabajador_id,
        :_destroy
      ]
    )
  end
end
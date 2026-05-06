class CooperacionesController < ApplicationController
  COOPERACIONES_POR_PAGINA = 10
  DESGLOSE_TRABAJADORES_POR_PAGINA = 15

  before_action :autenticar_usuario

  before_action -> { requiere_permiso!(:cooperaciones, :ver) },
                only: %i[
                  index
                  show
                  buscar_trabajadores
                  pdf_lista_general
                  pdf_recibos
                  ver_lista_confirmacion
                ]

  before_action -> { requiere_permiso!(:cooperaciones, :crear) },
                only: %i[new create]

  before_action -> { requiere_permiso!(:cooperaciones, :editar) },
                only: %i[
                  edit
                  update
                  cambiar_estado
                  confirmacion
                  confirmar
                  corregir_evidencia
                  actualizar_evidencia
                ]

  before_action :set_cooperacion,
                only: %i[
                  show
                  edit
                  update
                  cambiar_estado
                  pdf_lista_general
                  pdf_recibos
                  confirmacion
                  confirmar
                  ver_lista_confirmacion
                  corregir_evidencia
                  actualizar_evidencia
                ]

  def index
    @q = params[:q].to_s.strip
    @estado = params[:estado].to_s.strip

    base = Cooperacion
           .includes(:cooperacion_conceptos, :cooperacion_condonados, :cooperacion_detalles_confirmados)
           .buscar_por_nombre(@q)
           .filtrar_por_estado(@estado)
           .recientes

    @total_registros = base.count
    @total_paginas = (@total_registros.to_f / COOPERACIONES_POR_PAGINA).ceil
    @total_paginas = 1 if @total_paginas.zero?

    @pagina_actual = params[:page].to_i
    @pagina_actual = 1 if @pagina_actual < 1
    @pagina_actual = @total_paginas if @pagina_actual > @total_paginas

    offset = (@pagina_actual - 1) * COOPERACIONES_POR_PAGINA

    @cooperaciones = base
                     .offset(offset)
                     .limit(COOPERACIONES_POR_PAGINA)
  end

  def show
  @desglose_trabajadores = @cooperacion.desglose_por_trabajador
  @total_esperado = @cooperacion.total_esperado

  @total_desglose_registros = @desglose_trabajadores.size
  @desglose_total_paginas = (@total_desglose_registros.to_f / DESGLOSE_TRABAJADORES_POR_PAGINA).ceil
  @desglose_total_paginas = 1 if @desglose_total_paginas.zero?

  @desglose_pagina_actual = params[:desglose_page].to_i
  @desglose_pagina_actual = 1 if @desglose_pagina_actual < 1
  @desglose_pagina_actual = @desglose_total_paginas if @desglose_pagina_actual > @desglose_total_paginas

  offset = (@desglose_pagina_actual - 1) * DESGLOSE_TRABAJADORES_POR_PAGINA

  @desglose_trabajadores_paginados =
    @desglose_trabajadores.slice(offset, DESGLOSE_TRABAJADORES_POR_PAGINA) || []
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

    cargar_condonados_habituales
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
    if @cooperacion.completada?
      return redirect_to cooperacion_path(@cooperacion),
                         alert: "No se puede editar una cooperación completada"
    end

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
      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "cooperaciones",
        entidad: "Cooperacion",
        registro_id: @cooperacion.id,
        resumen: "Se cambió el estado de la cooperación #{@cooperacion.nombre} a #{nuevo_estado}",
        antes: snapshot_antes,
        despues: @cooperacion.snapshot_para_historial,
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

  def confirmacion
    unless @cooperacion.activa?
      return redirect_to cooperaciones_path,
                         alert: "Solo se pueden confirmar cooperaciones activas"
    end

    @total_esperado = @cooperacion.total_esperado
  end

  def confirmar
    unless @cooperacion.activa?
      return redirect_to cooperaciones_path,
                         alert: "Solo se pueden confirmar cooperaciones activas"
    end

    archivo = params[:lista_confirmacion_pdf]

    if archivo.blank?
      @total_esperado = @cooperacion.total_esperado
      flash.now[:alert] = "Debes subir el PDF escaneado de la lista de confirmación"
      return render :confirmacion, status: :unprocessable_entity
    end

    snapshot_antes = @cooperacion.snapshot_para_historial

    begin
      nombre_archivo = "lista_confirmacion_#{@cooperacion.nombre}.pdf"

      ruta_pdf = uploader_listas.upload_pdf!(
        uploaded_file: archivo,
        folder: "cooperaciones/#{@cooperacion.id}/confirmacion",
        filename: nombre_archivo
      )

      @cooperacion.transaction do
        @cooperacion.generar_snapshot_confirmado!

        @cooperacion.update!(
          estado: "completada",
          confirmada_at: Time.current,
          confirmada_por: usuario_actual,
          lista_confirmacion_pdf_path: ruta_pdf,
          observaciones_confirmacion: params[:observaciones_confirmacion].to_s.strip.presence
        )
      end

      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "cooperaciones",
        entidad: "Cooperacion",
        registro_id: @cooperacion.id,
        resumen: "Se confirmó la cooperación #{@cooperacion.nombre}",
        antes: snapshot_antes,
        despues: @cooperacion.reload.snapshot_para_historial,
        request: request
      )

      redirect_to cooperacion_path(@cooperacion), notice: "Cooperación confirmada correctamente"
    rescue Supabase::StorageUploader::Error => e
      @total_esperado = @cooperacion.total_esperado
      flash.now[:alert] = e.message
      render :confirmacion, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      @total_esperado = @cooperacion.total_esperado
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :confirmacion, status: :unprocessable_entity
    end
  end

  def ver_lista_confirmacion
    if @cooperacion.lista_confirmacion_pdf_path.blank?
      return redirect_to cooperacion_path(@cooperacion),
                         alert: "Esta cooperación no tiene PDF de confirmación registrado"
    end

    url = uploader_listas.signed_url!(
      object_path: @cooperacion.lista_confirmacion_pdf_path,
      expires_in: 3600
    )

    redirect_to url, allow_other_host: true
  rescue Supabase::StorageUploader::Error => e
    redirect_to cooperacion_path(@cooperacion), alert: e.message
  end

  def corregir_evidencia
    unless @cooperacion.completada?
      return redirect_to cooperacion_path(@cooperacion),
                         alert: "Solo se puede corregir evidencia de cooperaciones completadas"
    end
  end

  def actualizar_evidencia
    unless @cooperacion.completada?
      return redirect_to cooperacion_path(@cooperacion),
                         alert: "Solo se puede corregir evidencia de cooperaciones completadas"
    end

    archivo = params[:lista_confirmacion_pdf]
    motivo = params[:motivo_correccion].to_s.strip

    if archivo.blank? || motivo.blank?
      flash.now[:alert] = "Debes subir un PDF y escribir el motivo de la corrección"
      return render :corregir_evidencia, status: :unprocessable_entity
    end

    snapshot_antes = @cooperacion.snapshot_para_historial
    ruta_anterior = @cooperacion.lista_confirmacion_pdf_path

    begin
      nombre_archivo = "lista_confirmacion_#{@cooperacion.nombre}_corregida_#{Time.current.strftime('%Y%m%d%H%M%S')}.pdf"

      nueva_ruta_pdf = uploader_listas.upload_pdf!(
        uploaded_file: archivo,
        folder: "cooperaciones/#{@cooperacion.id}/confirmacion/correcciones",
        filename: nombre_archivo
      )

      observaciones_actuales = @cooperacion.observaciones_confirmacion.to_s.strip

      nueva_observacion = [
        observaciones_actuales.presence,
        "Corrección de evidencia #{Time.current.strftime('%d/%m/%Y %H:%M')} por #{usuario_actual&.nombre_usuario}: #{motivo}"
      ].compact.join("\n\n")

      @cooperacion.update!(
        lista_confirmacion_pdf_path: nueva_ruta_pdf,
        observaciones_confirmacion: nueva_observacion
      )

      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "cooperaciones",
        entidad: "Cooperacion",
        registro_id: @cooperacion.id,
        resumen: "Se corrigió el PDF de evidencia de la cooperación #{@cooperacion.nombre}",
        antes: snapshot_antes.merge(
          evidencia_anterior: ruta_anterior
        ),
        despues: @cooperacion.snapshot_para_historial.merge(
          evidencia_nueva: nueva_ruta_pdf,
          motivo_correccion: motivo
        ),
        request: request
      )

      redirect_to cooperacion_path(@cooperacion), notice: "Evidencia corregida correctamente"
    rescue Supabase::StorageUploader::Error => e
      flash.now[:alert] = e.message
      render :corregir_evidencia, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :corregir_evidencia, status: :unprocessable_entity
    end
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

  def cargar_condonados_habituales
    Trabajador.condonados_habituales.find_each do |trabajador|
      @cooperacion.cooperacion_condonados.build(trabajador: trabajador)
    end
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

  def uploader_listas
    Supabase::StorageUploader.new(
      bucket: ENV["SUPABASE_LISTAS_COOPERACIONES_BUCKET"].presence || ENV["SUPABASE_STORAGE_BUCKET"]
    )
  end
end
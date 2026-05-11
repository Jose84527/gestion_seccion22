class EgresosController < ApplicationController
  EGRESOS_POR_PAGINA = 10

  before_action :autenticar_usuario
  before_action :requiere_cuenta_financiera_para_finanzas!
  before_action :cargar_contexto_financiero

  before_action -> { requiere_permiso!(:cooperaciones, :ver) },
                only: %i[index show pdf ver_evidencia]

  before_action -> { requiere_permiso!(:cooperaciones, :crear) },
                only: %i[new create]

  before_action -> { requiere_permiso!(:cooperaciones, :editar) },
                only: %i[
                  edit
                  update
                  cancelar
                  confirmacion
                  confirmar
                  corregir_evidencia
                  actualizar_evidencia
                ]

  before_action :set_egreso,
                only: %i[
                  show
                  edit
                  update
                  cancelar
                  pdf
                  confirmacion
                  confirmar
                  ver_evidencia
                  corregir_evidencia
                  actualizar_evidencia
                ]

  def index
    @q = params[:q].to_s.strip
    @estado = params[:estado].to_s.strip

    base = egresos_visibles
           .includes(:cuenta_financiera)
           .buscar_por_texto(@q)
           .filtrar_por_estado(@estado)
           .ordenados_por_folio

    @total_registros = base.count
    @total_paginas = (@total_registros.to_f / EGRESOS_POR_PAGINA).ceil
    @total_paginas = 1 if @total_paginas.zero?

    @pagina_actual = params[:page].to_i
    @pagina_actual = 1 if @pagina_actual < 1
    @pagina_actual = @total_paginas if @pagina_actual > @total_paginas

    offset = (@pagina_actual - 1) * EGRESOS_POR_PAGINA

    @egresos = base
               .offset(offset)
               .limit(EGRESOS_POR_PAGINA)
  end

  def show
  end

  def new
    @egreso = Egreso.new(
      fecha_egreso: Date.current,
      estado: "registrado"
    )

    asignar_cuenta_financiera_a_registro(@egreso)
  end

  def create
    parametros = egreso_params

    @egreso = Egreso.new(parametros)
    @egreso.estado = "registrado"

    asignar_cuenta_financiera_a_registro(@egreso, parametros)

    if @egreso.save
      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "crear",
        modulo: "egresos",
        entidad: "Egreso",
        registro_id: @egreso.id,
        resumen: "Se creó el egreso #{@egreso.folio_np}",
        antes: nil,
        despues: @egreso.snapshot_para_historial,
        request: request
      )

      redirect_to egreso_path(@egreso), notice: "Egreso registrado correctamente"
    else
      flash.now[:alert] = "No se pudo registrar el egreso"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @egreso.editable?
      return redirect_to egreso_path(@egreso),
                         alert: "Solo se pueden editar egresos registrados"
    end
  end

  def update
    unless @egreso.editable?
      return redirect_to egreso_path(@egreso),
                         alert: "Solo se pueden editar egresos registrados"
    end

    snapshot_antes = @egreso.snapshot_para_historial
    parametros = egreso_params

    if @egreso.update(parametros)
      snapshot_despues = @egreso.snapshot_para_historial

      if snapshot_antes != snapshot_despues
        Historiales::Registrador.registrar!(
          usuario: usuario_actual,
          accion: "editar",
          modulo: "egresos",
          entidad: "Egreso",
          registro_id: @egreso.id,
          resumen: "Se actualizó el egreso #{@egreso.folio_np}",
          antes: snapshot_antes,
          despues: snapshot_despues,
          request: request
        )
      end

      redirect_to egreso_path(@egreso), notice: "Egreso actualizado correctamente"
    else
      flash.now[:alert] = "No se pudo actualizar el egreso"
      render :edit, status: :unprocessable_entity
    end
  end

  def cancelar
    unless @egreso.cancelable?
      return redirect_to egreso_path(@egreso),
                         alert: "Solo se pueden cancelar egresos registrados"
    end

    snapshot_antes = @egreso.snapshot_para_historial

    if @egreso.update(estado: "cancelado")
      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "egresos",
        entidad: "Egreso",
        registro_id: @egreso.id,
        resumen: "Se canceló el egreso #{@egreso.folio_np}",
        antes: snapshot_antes,
        despues: @egreso.snapshot_para_historial,
        request: request
      )

      redirect_to egresos_path, notice: "Egreso cancelado correctamente"
    else
      redirect_to egreso_path(@egreso), alert: "No se pudo cancelar el egreso"
    end
  end

  def pdf
    if @egreso.cancelado?
      return redirect_to egreso_path(@egreso),
                         alert: "No se puede generar PDF de un egreso cancelado"
    end

    pdf = Pdf::EgresoPdf.new(@egreso).render

    send_data pdf,
              filename: "egreso_#{@egreso.folio_np.parameterize(separator: '_')}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  def confirmacion
    unless @egreso.confirmable?
      return redirect_to egreso_path(@egreso),
                         alert: "Solo se pueden confirmar egresos registrados"
    end
  end

  def confirmar
    unless @egreso.confirmable?
      return redirect_to egreso_path(@egreso),
                         alert: "Solo se pueden confirmar egresos registrados"
    end

    archivo = params[:evidencia_pdf]

    if archivo.blank?
      flash.now[:alert] = "Debes subir el PDF escaneado del egreso"
      return render :confirmacion, status: :unprocessable_entity
    end

    snapshot_antes = @egreso.snapshot_para_historial

    begin
      nombre_archivo = "egreso_#{@egreso.folio_np.parameterize(separator: '_')}_confirmado.pdf"

      ruta_pdf = uploader_egresos.upload_pdf!(
        uploaded_file: archivo,
        folder: "egresos/#{@egreso.id}/evidencia",
        filename: nombre_archivo
      )

      @egreso.update!(
        estado: "confirmado",
        confirmado_at: Time.current,
        evidencia_pdf_path: ruta_pdf,
        observaciones_evidencia: params[:observaciones_evidencia].to_s.strip.presence
      )

      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "egresos",
        entidad: "Egreso",
        registro_id: @egreso.id,
        resumen: "Se confirmó el egreso #{@egreso.folio_np}",
        antes: snapshot_antes,
        despues: @egreso.snapshot_para_historial,
        request: request
      )

      redirect_to egreso_path(@egreso), notice: "Egreso confirmado correctamente"
    rescue Supabase::StorageUploader::Error => e
      flash.now[:alert] = e.message
      render :confirmacion, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :confirmacion, status: :unprocessable_entity
    end
  end

  def ver_evidencia
    if @egreso.evidencia_pdf_path.blank?
      return redirect_to egreso_path(@egreso),
                         alert: "Este egreso no tiene evidencia registrada"
    end

    url = uploader_egresos.signed_url!(
      object_path: @egreso.evidencia_pdf_path,
      expires_in: 3600
    )

    redirect_to url, allow_other_host: true
  rescue Supabase::StorageUploader::Error => e
    redirect_to egreso_path(@egreso), alert: e.message
  end

  def corregir_evidencia
    unless @egreso.confirmado?
      return redirect_to egreso_path(@egreso),
                         alert: "Solo se puede corregir evidencia de egresos confirmados"
    end
  end

  def actualizar_evidencia
    unless @egreso.confirmado?
      return redirect_to egreso_path(@egreso),
                         alert: "Solo se puede corregir evidencia de egresos confirmados"
    end

    archivo = params[:evidencia_pdf]
    motivo = params[:motivo_correccion].to_s.strip

    if archivo.blank? || motivo.blank?
      flash.now[:alert] = "Debes subir un PDF y escribir el motivo de la corrección"
      return render :corregir_evidencia, status: :unprocessable_entity
    end

    snapshot_antes = @egreso.snapshot_para_historial
    ruta_anterior = @egreso.evidencia_pdf_path

    begin
      nombre_archivo = "egreso_#{@egreso.folio_np.parameterize(separator: '_')}_corregido_#{Time.current.strftime('%Y%m%d%H%M%S')}.pdf"

      nueva_ruta_pdf = uploader_egresos.upload_pdf!(
        uploaded_file: archivo,
        folder: "egresos/#{@egreso.id}/evidencia/correcciones",
        filename: nombre_archivo
      )

      observaciones_actuales = @egreso.observaciones_evidencia.to_s.strip

      nueva_observacion = [
        observaciones_actuales.presence,
        "Corrección de evidencia #{Time.current.strftime('%d/%m/%Y %H:%M')} por #{usuario_actual&.nombre_usuario}: #{motivo}"
      ].compact.join("\n\n")

      @egreso.update!(
        evidencia_pdf_path: nueva_ruta_pdf,
        observaciones_evidencia: nueva_observacion
      )

      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "egresos",
        entidad: "Egreso",
        registro_id: @egreso.id,
        resumen: "Se corrigió la evidencia del egreso #{@egreso.folio_np}",
        antes: snapshot_antes.merge(
          evidencia_anterior: ruta_anterior
        ),
        despues: @egreso.snapshot_para_historial.merge(
          evidencia_nueva: nueva_ruta_pdf,
          motivo_correccion: motivo
        ),
        request: request
      )

      redirect_to egreso_path(@egreso), notice: "Evidencia corregida correctamente"
    rescue Supabase::StorageUploader::Error => e
      flash.now[:alert] = e.message
      render :corregir_evidencia, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :corregir_evidencia, status: :unprocessable_entity
    end
  end

  private

  def egresos_visibles
    aplicar_cuenta_financiera(Egreso.all)
  end

  def set_egreso
    @egreso = egresos_visibles.find(params[:id])
  end

  def cargar_contexto_financiero
    @cuentas_financieras = cuentas_financieras_disponibles
    @cuenta_financiera_actual = cuenta_financiera_contexto
  end

  def egreso_params
    permitidos = params.require(:egreso).permit(
      :monto,
      :concepto,
      :fecha_egreso,
      :observaciones,
      :cuenta_financiera_id
    )

    permitidos.delete(:cuenta_financiera_id) unless admin_actual?

    permitidos
  end

  def uploader_egresos
    Supabase::StorageUploader.new(
      bucket: ENV["SUPABASE_EGRESOS_BUCKET"].presence || ENV["SUPABASE_STORAGE_BUCKET"]
    )
  end
end
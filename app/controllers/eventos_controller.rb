class EventosController < ApplicationController
  EVENTOS_POR_PAGINA = 10
  TRABAJADORES_POR_PAGINA = 10

  before_action :autenticar_usuario

  before_action -> { requiere_permiso!(:eventos, :ver) },
                only: %i[
                  index
                  show
                  buscar_trabajadores
                  ver_convocatoria
                  ver_acta
                  ver_lista_participacion
                ]

  before_action -> { requiere_permiso!(:eventos, :crear) },
                only: %i[new create]

  before_action -> { requiere_permiso!(:eventos, :editar) },
                only: %i[edit update]

  before_action -> { requiere_permiso!(:eventos, :cancelar) },
                only: %i[cancelar]

  before_action -> { requiere_permiso!(:eventos, :confirmar) },
                only: %i[confirmacion confirmar]

  before_action :set_evento,
                only: %i[
                  show
                  edit
                  update
                  cancelar
                  confirmacion
                  confirmar
                  ver_convocatoria
                  ver_acta
                  ver_lista_participacion
                ]

  def index
    @q = params[:q].to_s.strip
    @estado = params[:estado].to_s.strip

    base = Evento
           .buscar_por_texto(@q)
           .filtrar_por_estado(@estado)
           .ordenados_por_fecha

    @total_registros = base.count
    @total_paginas = (@total_registros.to_f / EVENTOS_POR_PAGINA).ceil
    @total_paginas = 1 if @total_paginas.zero?

    @pagina_actual = params[:page].to_i
    @pagina_actual = 1 if @pagina_actual < 1
    @pagina_actual = @total_paginas if @pagina_actual > @total_paginas

    offset = (@pagina_actual - 1) * EVENTOS_POR_PAGINA

    @eventos = base
               .offset(offset)
               .limit(EVENTOS_POR_PAGINA)
  end

  def show
    @asistencias = @evento
                   .evento_asistencias
                   .includes(:trabajador)
                   .order(created_at: :asc)

    @total_asistentes = @asistencias.size
    @total_puntos_asignados = @asistencias.sum(&:puntaje_asignado)
  end

  def new
    @evento = Evento.new(
      fecha_inicio: Time.current.change(sec: 0),
      fecha_fin: 1.hour.from_now.change(sec: 0),
      puntaje: 0,
      estado: "programado"
    )
  end

  def create
    @evento = Evento.new(evento_params)
    @evento.estado = "programado"

    archivo_convocatoria = params[:convocatoria_pdf]
    archivo_acta = params[:acta_pdf]

    validar_evento_y_documentos_para_creacion(archivo_convocatoria, archivo_acta)

    if @evento.errors.any?
      flash.now[:alert] = "No se pudo crear el evento. Revisa los campos marcados."
      return render :new, status: :unprocessable_entity
    end

    begin
      ruta_convocatoria = uploader_eventos.upload_pdf!(
        uploaded_file: archivo_convocatoria,
        folder: "eventos/convocatorias",
        filename: nombre_archivo_evento("convocatoria", @evento.nombre)
      )

      ruta_acta = uploader_eventos.upload_pdf!(
        uploaded_file: archivo_acta,
        folder: "eventos/actas",
        filename: nombre_archivo_evento("acta", @evento.nombre)
      )

      @evento.convocatoria_pdf_path = ruta_convocatoria
      @evento.acta_pdf_path = ruta_acta
      @evento.save!

      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "crear",
        modulo: "eventos",
        entidad: "Evento",
        registro_id: @evento.id,
        resumen: "Se creó el evento #{@evento.nombre}",
        antes: nil,
        despues: @evento.snapshot_para_historial,
        request: request
      )

      redirect_to evento_path(@evento), notice: "Evento creado correctamente"
    rescue Supabase::StorageUploader::Error => e
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @evento.editable?
      return redirect_to evento_path(@evento),
                         alert: "Solo se pueden editar eventos programados"
    end
  end

  def update
    unless @evento.editable?
      return redirect_to evento_path(@evento),
                         alert: "Solo se pueden editar eventos programados"
    end

    snapshot_antes = @evento.snapshot_para_historial

    if @evento.update(evento_params)
      snapshot_despues = @evento.snapshot_para_historial

      if snapshot_antes != snapshot_despues
        Historiales::Registrador.registrar!(
          usuario: usuario_actual,
          accion: "editar",
          modulo: "eventos",
          entidad: "Evento",
          registro_id: @evento.id,
          resumen: "Se actualizó el evento #{@evento.nombre}",
          antes: snapshot_antes,
          despues: snapshot_despues,
          request: request
        )
      end

      redirect_to evento_path(@evento), notice: "Evento actualizado correctamente"
    else
      flash.now[:alert] = "No se pudo actualizar el evento"
      render :edit, status: :unprocessable_entity
    end
  end

  def cancelar
    unless @evento.cancelable?
      return redirect_to evento_path(@evento),
                         alert: "Solo se pueden cancelar eventos programados"
    end

    snapshot_antes = @evento.snapshot_para_historial

    if @evento.update(estado: "cancelado")
      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "eventos",
        entidad: "Evento",
        registro_id: @evento.id,
        resumen: "Se canceló el evento #{@evento.nombre}",
        antes: snapshot_antes,
        despues: @evento.snapshot_para_historial,
        request: request
      )

      redirect_to eventos_path, notice: "Evento cancelado correctamente"
    else
      redirect_to evento_path(@evento), alert: "No se pudo cancelar el evento"
    end
  end

  def confirmacion
    unless @evento.confirmable?
      return redirect_to evento_path(@evento),
                         alert: "Solo se pueden confirmar eventos programados"
    end

    cargar_asistentes_seleccionados
  end

  def confirmar
    unless @evento.confirmable?
      return redirect_to evento_path(@evento),
                         alert: "Solo se pueden confirmar eventos programados"
    end

    archivo = params[:lista_participacion_pdf]
    asistentes_ids = Array(params[:asistentes_ids]).map(&:to_s).reject(&:blank?).uniq

    if archivo.blank?
      cargar_asistentes_seleccionados
      flash.now[:alert] = "Debes subir el PDF escaneado de la lista de participación"
      return render :confirmacion, status: :unprocessable_entity
    end

    if asistentes_ids.blank?
      cargar_asistentes_seleccionados
      flash.now[:alert] = "Debes seleccionar al menos un trabajador asistente"
      return render :confirmacion, status: :unprocessable_entity
    end

    trabajadores = Trabajador
                   .where(id: asistentes_ids, estado_trabajador: "activo")
                   .ordenados

    if trabajadores.blank?
      cargar_asistentes_seleccionados
      flash.now[:alert] = "No se encontraron trabajadores activos para registrar asistencia"
      return render :confirmacion, status: :unprocessable_entity
    end

    snapshot_antes = @evento.snapshot_para_historial

    begin
      ruta_pdf = uploader_eventos.upload_pdf!(
        uploaded_file: archivo,
        folder: "eventos/#{@evento.id}/lista_participacion",
        filename: nombre_archivo_evento("lista_participacion", @evento.nombre)
      )

      @evento.transaction do
        @evento.evento_asistencias.destroy_all

        trabajadores.each do |trabajador|
          @evento.evento_asistencias.create!(
            trabajador: trabajador,
            puntaje_asignado: @evento.puntaje
          )
        end

        @evento.update!(
          estado: "confirmado",
          confirmado_at: Time.current,
          confirmado_por: usuario_actual,
          lista_participacion_pdf_path: ruta_pdf,
          observaciones_confirmacion: params[:observaciones_confirmacion].to_s.strip.presence
        )
      end

      Historiales::Registrador.registrar!(
        usuario: usuario_actual,
        accion: "editar",
        modulo: "eventos",
        entidad: "Evento",
        registro_id: @evento.id,
        resumen: "Se confirmó el evento #{@evento.nombre} con #{trabajadores.size} asistentes",
        antes: snapshot_antes,
        despues: @evento.reload.snapshot_para_historial,
        request: request
      )

      redirect_to evento_path(@evento), notice: "Evento confirmado correctamente"
    rescue Supabase::StorageUploader::Error => e
      cargar_asistentes_seleccionados
      flash.now[:alert] = e.message
      render :confirmacion, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      cargar_asistentes_seleccionados
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :confirmacion, status: :unprocessable_entity
    end
  end

  def ver_convocatoria
    if @evento.convocatoria_pdf_path.blank?
      return redirect_to evento_path(@evento),
                         alert: "Este evento no tiene convocatoria registrada"
    end

    url = uploader_eventos.signed_url!(
      object_path: @evento.convocatoria_pdf_path,
      expires_in: 3600
    )

    redirect_to url, allow_other_host: true
  rescue Supabase::StorageUploader::Error => e
    redirect_to evento_path(@evento), alert: e.message
  end

  def ver_acta
    if @evento.acta_pdf_path.blank?
      return redirect_to evento_path(@evento),
                         alert: "Este evento no tiene acta registrada"
    end

    url = uploader_eventos.signed_url!(
      object_path: @evento.acta_pdf_path,
      expires_in: 3600
    )

    redirect_to url, allow_other_host: true
  rescue Supabase::StorageUploader::Error => e
    redirect_to evento_path(@evento), alert: e.message
  end

  def ver_lista_participacion
    if @evento.lista_participacion_pdf_path.blank?
      return redirect_to evento_path(@evento),
                         alert: "Este evento no tiene lista de participación registrada"
    end

    url = uploader_eventos.signed_url!(
      object_path: @evento.lista_participacion_pdf_path,
      expires_in: 3600
    )

    redirect_to url, allow_other_host: true
  rescue Supabase::StorageUploader::Error => e
    redirect_to evento_path(@evento), alert: e.message
  end

  def buscar_trabajadores
    termino = params[:q].to_s.strip
    pagina = params[:page].to_i
    pagina = 1 if pagina < 1

    base = Trabajador
           .includes(:concepto07_nivel)
           .where(estado_trabajador: "activo")

    if termino.present?
      termino_limpio = ActiveRecord::Base.sanitize_sql_like(termino)

      base = base.where(
        "nombres ILIKE :q OR apellido_paterno ILIKE :q OR apellido_materno ILIKE :q OR rfc ILIKE :q OR clave_cobro ILIKE :q",
        q: "%#{termino_limpio}%"
      )
    end

    base = base.ordenados

    total_registros = base.count
    total_paginas = (total_registros.to_f / TRABAJADORES_POR_PAGINA).ceil
    total_paginas = 1 if total_paginas.zero?
    pagina = total_paginas if pagina > total_paginas

    trabajadores = base
                   .offset((pagina - 1) * TRABAJADORES_POR_PAGINA)
                   .limit(TRABAJADORES_POR_PAGINA)

    render json: {
      trabajadores: trabajadores.map { |trabajador|
        {
          id: trabajador.id,
          nombre: trabajador.nombre_completo,
          rfc: trabajador.rfc,
          clave_cobro: trabajador.clave_cobro,
          tipo_trabajador: trabajador.tipo_trabajador&.humanize,
          etiqueta: "#{trabajador.nombre_completo} · #{trabajador.rfc} · #{trabajador.clave_cobro}"
        }
      },
      pagina_actual: pagina,
      total_paginas: total_paginas,
      total_registros: total_registros
    }
  end

  private

  def set_evento
    @evento = Evento.find(params[:id])
  end

  def evento_params
    params.require(:evento).permit(
      :nombre,
      :descripcion,
      :lugar,
      :fecha_inicio,
      :fecha_fin,
      :puntaje
    )
  end

  def cargar_asistentes_seleccionados
    ids = Array(params[:asistentes_ids]).map(&:to_s).reject(&:blank?).uniq

    @asistentes_seleccionados =
      if ids.any?
        Trabajador.where(id: ids).ordenados
      else
        []
      end
  end

  def validar_evento_y_documentos_para_creacion(archivo_convocatoria, archivo_acta)
    @evento.valid?

    @evento.errors.delete(:convocatoria_pdf_path)
    @evento.errors.delete(:acta_pdf_path)

    if archivo_convocatoria.blank?
      @evento.errors.add(:convocatoria_pdf_path, "es obligatoria")
    end

    if archivo_acta.blank?
      @evento.errors.add(:acta_pdf_path, "es obligatoria")
    end
  end

  def uploader_eventos
    Supabase::StorageUploader.new(
      bucket: ENV["SUPABASE_EVENTOS_BUCKET"].presence || ENV["SUPABASE_STORAGE_BUCKET"]
    )
  end

  def nombre_archivo_evento(prefijo, nombre_evento)
    nombre_limpio = nombre_evento.to_s.parameterize(separator: "_").presence || "evento"

    "#{prefijo}_#{nombre_limpio}_#{Time.current.strftime('%Y%m%d%H%M%S')}.pdf"
  end
end
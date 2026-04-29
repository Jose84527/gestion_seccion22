require "net/http"
require "json"

module Supabase
  class StorageUploader
    class Error < StandardError; end

    def initialize(
      supabase_url: ENV["SUPABASE_URL"],
      service_role_key: ENV["SUPABASE_SERVICE_ROLE_KEY"] || ENV["SUPABASE_SECRET_KEY"],
      bucket: ENV["SUPABASE_LISTAS_COOPERACIONES_BUCKET"].presence || ENV["SUPABASE_STORAGE_BUCKET"]
    )
      @supabase_url = supabase_url.to_s.chomp("/")
      @service_role_key = service_role_key.to_s
      @bucket = bucket.to_s
    end

    def upload_pdf!(uploaded_file:, folder:, filename:)
      validar_configuracion!
      validar_archivo_pdf!(uploaded_file)

      object_path = [
        sanitizar_carpeta(folder),
        sanitizar_nombre_archivo(filename)
      ].join("/")

      upload!(
        uploaded_file: uploaded_file,
        object_path: object_path,
        content_type: "application/pdf"
      )

      object_path
    end

    def signed_url!(object_path:, expires_in: 3600)
      validar_configuracion!

      raise Error, "No hay ruta de archivo para generar la URL" if object_path.blank?

      encoded_bucket = URI.encode_www_form_component(@bucket)
      encoded_path = object_path.split("/").map { |segmento| URI.encode_www_form_component(segmento) }.join("/")

      uri = URI("#{@supabase_url}/storage/v1/object/sign/#{encoded_bucket}/#{encoded_path}")

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@service_role_key}"
      request["apikey"] = @service_role_key
      request["Content-Type"] = "application/json"
      request.body = { expiresIn: expires_in }.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "Error al generar URL firmada: #{response.code} #{response.body}"
      end

      body = JSON.parse(response.body)
      signed_url = body["signedURL"]

      raise Error, "Supabase no devolvió URL firmada" if signed_url.blank?

      construir_url_firmada(signed_url)
    end

    private

    def upload!(uploaded_file:, object_path:, content_type:)
      encoded_bucket = URI.encode_www_form_component(@bucket)
      encoded_path = object_path.split("/").map { |segmento| URI.encode_www_form_component(segmento) }.join("/")

      uri = URI("#{@supabase_url}/storage/v1/object/#{encoded_bucket}/#{encoded_path}")

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@service_role_key}"
      request["apikey"] = @service_role_key
      request["Content-Type"] = content_type
      request["x-upsert"] = "true"

      uploaded_file.tempfile.rewind
      request.body = uploaded_file.tempfile.read

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      return if response.is_a?(Net::HTTPSuccess)

      raise Error, "Error al subir archivo a Supabase: #{response.code} #{response.body}"
    end

    def construir_url_firmada(signed_url)
      return signed_url if signed_url.start_with?("http://", "https://")

      if signed_url.start_with?("/storage/v1")
        "#{@supabase_url}#{signed_url}"
      elsif signed_url.start_with?("/object/")
        "#{@supabase_url}/storage/v1#{signed_url}"
      else
        "#{@supabase_url}/storage/v1/#{signed_url.delete_prefix("/")}"
      end
    end

    def validar_configuracion!
      raise Error, "Falta SUPABASE_URL" if @supabase_url.blank?
      raise Error, "Falta SUPABASE_SERVICE_ROLE_KEY" if @service_role_key.blank?
      raise Error, "Falta SUPABASE_LISTAS_COOPERACIONES_BUCKET o SUPABASE_STORAGE_BUCKET" if @bucket.blank?
    end

    def validar_archivo_pdf!(uploaded_file)
      raise Error, "Debes seleccionar un archivo PDF" if uploaded_file.blank?

      filename = uploaded_file.original_filename.to_s.downcase
      content_type = uploaded_file.content_type.to_s

      es_pdf = filename.end_with?(".pdf") || content_type == "application/pdf"

      raise Error, "El archivo debe ser PDF" unless es_pdf
    end

    def sanitizar_carpeta(valor)
      valor.to_s
           .split("/")
           .map { |segmento| segmento.parameterize(separator: "_") }
           .reject(&:blank?)
           .join("/")
           .presence || "archivos"
    end

    def sanitizar_nombre_archivo(valor)
      base = File.basename(valor.to_s, ".pdf")
      base_seguro = base.parameterize(separator: "_").presence || "archivo"

      "#{base_seguro}.pdf"
    end
  end
end
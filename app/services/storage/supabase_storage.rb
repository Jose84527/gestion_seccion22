require "net/http"
require "json"
require "uri"

module Storage
  class SupabaseStorage
    class Error < StandardError; end

    def initialize(config: SUPABASE_STORAGE_CONFIG)
      @url = config.fetch(:url)
      @secret_key = config.fetch(:secret_key)
      @bucket = config.fetch(:bucket)
    end

    def subir_archivo!(object_key:, io:, content_type:)
      request = Net::HTTP::Post.new(storage_object_url(object_key))
      request["Authorization"] = "Bearer #{@secret_key}"
      request["apikey"] = @secret_key
      request["Content-Type"] = content_type
      request["x-upsert"] = "false"
      request.body = io.read

      response = perform_request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "No se pudo subir el archivo: #{response.code} - #{response.body}"
      end

      {
        bucket: @bucket,
        object_key: object_key
      }
    end

    def eliminar_archivo!(object_key:)
      request = Net::HTTP::Delete.new(storage_object_url(object_key))
      request["Authorization"] = "Bearer #{@secret_key}"
      request["apikey"] = @secret_key

      response = perform_request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "No se pudo eliminar el archivo: #{response.code} - #{response.body}"
      end

      true
    end

    def reemplazar_archivo!(object_key:, io:, content_type:)
      request = Net::HTTP::Post.new(storage_object_url(object_key))
      request["Authorization"] = "Bearer #{@secret_key}"
      request["apikey"] = @secret_key
      request["Content-Type"] = content_type
      request["x-upsert"] = "true"
      request.body = io.read

      response = perform_request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "No se pudo reemplazar el archivo: #{response.code} - #{response.body}"
      end

      {
        bucket: @bucket,
        object_key: object_key
      }
    end

    def generar_url_firmada!(object_key:, expires_in: 300)
      request = Net::HTTP::Post.new(signed_url_endpoint(object_key))
      request["Authorization"] = "Bearer #{@secret_key}"
      request["apikey"] = @secret_key
      request["Content-Type"] = "application/json"
      request.body = { expiresIn: expires_in }.to_json

      response = perform_request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "No se pudo generar la URL firmada: #{response.code} - #{response.body}"
      end

      payload = JSON.parse(response.body)
      signed_path = payload["signedURL"] || payload["signedUrl"]

      raise Error, "La respuesta no incluyó signedURL" if signed_path.blank?

      "#{@url}/storage/v1#{signed_path}"
    end

    private

    def storage_object_url(object_key)
      uri = URI.parse("#{@url}/storage/v1/object/#{@bucket}/#{escape_object_key(object_key)}")
      uri
    end

    def signed_url_endpoint(object_key)
      URI.parse("#{@url}/storage/v1/object/sign/#{@bucket}/#{escape_object_key(object_key)}")
    end

    def escape_object_key(object_key)
      object_key
        .split("/")
        .map { |segmento| CGI.escape(segmento) }
        .join("/")
    end

    def perform_request(request)
      uri = request.uri

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
    end
  end
end
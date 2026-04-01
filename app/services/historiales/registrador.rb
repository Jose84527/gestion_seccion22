module Historiales
  class Registrador
    def self.registrar!(usuario:, accion:, modulo:, entidad:, registro_id:, resumen:, antes: nil, despues: nil, request: nil)
      Historial.create!(
        usuario: usuario,
        nombre_usuario: usuario&.nombre_usuario.to_s.presence || "sistema",
        fecha_evento: Time.current,
        accion: accion,
        modulo: modulo,
        entidad: entidad,
        registro_id: registro_id,
        resumen: resumen,
        antes_json: antes,
        despues_json: despues,
        ip: request&.remote_ip,
        user_agent: request&.user_agent,
        request_id: request&.request_id
      )
    end
  end
end
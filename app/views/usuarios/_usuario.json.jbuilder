json.extract! usuario, :id, :nombre_completo, :username, :email, :password_digest, :created_at, :updated_at
json.url usuario_url(usuario, format: :json)

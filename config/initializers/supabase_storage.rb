SUPABASE_STORAGE_CONFIG = {
  url: ENV.fetch("SUPABASE_URL"),
  secret_key: ENV.fetch("SUPABASE_SECRET_KEY"),
  bucket: ENV.fetch("SUPABASE_STORAGE_BUCKET")
}.freeze
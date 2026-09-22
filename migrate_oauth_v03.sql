-- OAuth v0.3 migration: dynamically registered OAuth clients (RFC 7591).
-- Clients registered through POST /oauth/register are resolved alongside CIMD
-- clients at /oauth/authorize; secrets are stored as SHA-256 hashes only.

CREATE TABLE IF NOT EXISTS oauth_clients (
  client_id TEXT NOT NULL UNIQUE,
  client_name TEXT NOT NULL,
  redirect_uris TEXT NOT NULL,
  client_secret_hash TEXT,
  scope TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  revoked_at INTEGER,
  CHECK (revoked_at IS NULL OR revoked_at >= created_at)
);

CREATE INDEX IF NOT EXISTS idx_oauth_clients_lookup
  ON oauth_clients (client_id, revoked_at);

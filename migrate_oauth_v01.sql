-- OAuth v0.1 migration: durable opaque authorization codes and tokens.
-- Secrets are never stored here; callers persist SHA-256 hashes only.

CREATE TABLE IF NOT EXISTS oauth_authorization_codes (
  code_hash TEXT NOT NULL UNIQUE,
  client_id TEXT NOT NULL,
  redirect_uri TEXT NOT NULL,
  resource TEXT NOT NULL,
  scope TEXT NOT NULL,
  code_challenge TEXT NOT NULL,
  code_challenge_method TEXT NOT NULL CHECK (code_challenge_method = 'S256'),
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  consumed_at INTEGER,
  CHECK (expires_at > created_at),
  CHECK (consumed_at IS NULL OR consumed_at >= created_at)
);

CREATE INDEX IF NOT EXISTS idx_oauth_authorization_codes_expiry
  ON oauth_authorization_codes (expires_at, consumed_at);

CREATE TABLE IF NOT EXISTS oauth_access_tokens (
  token_hash TEXT NOT NULL UNIQUE,
  client_id TEXT NOT NULL,
  resource TEXT NOT NULL,
  scope TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  revoked_at INTEGER,
  CHECK (expires_at > created_at),
  CHECK (revoked_at IS NULL OR revoked_at >= created_at)
);

CREATE INDEX IF NOT EXISTS idx_oauth_access_tokens_lookup
  ON oauth_access_tokens (token_hash, expires_at, revoked_at);
CREATE INDEX IF NOT EXISTS idx_oauth_access_tokens_expiry
  ON oauth_access_tokens (expires_at, revoked_at);

CREATE TABLE IF NOT EXISTS oauth_refresh_tokens (
  token_hash TEXT NOT NULL UNIQUE,
  family_hash TEXT NOT NULL,
  client_id TEXT NOT NULL,
  resource TEXT NOT NULL,
  scope TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  consumed_at INTEGER,
  revoked_at INTEGER,
  replacement_token_hash TEXT UNIQUE,
  CHECK (expires_at > created_at),
  CHECK (consumed_at IS NULL OR consumed_at >= created_at),
  CHECK (revoked_at IS NULL OR revoked_at >= created_at),
  CHECK (replacement_token_hash IS NULL OR replacement_token_hash != token_hash)
);

CREATE INDEX IF NOT EXISTS idx_oauth_refresh_tokens_lookup
  ON oauth_refresh_tokens (token_hash, expires_at, consumed_at, revoked_at);
CREATE INDEX IF NOT EXISTS idx_oauth_refresh_tokens_family
  ON oauth_refresh_tokens (family_hash, consumed_at, revoked_at);
CREATE INDEX IF NOT EXISTS idx_oauth_refresh_tokens_expiry
  ON oauth_refresh_tokens (expires_at, consumed_at, revoked_at);

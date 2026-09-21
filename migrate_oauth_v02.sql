-- OAuth v0.2 migration: strongly consistent WebAuthn challenge storage.
-- OAuth credentials remain in OAUTH_AUTH KV; only the short-lived challenge
-- needed to verify an assertion is stored here so authorize and verify may
-- safely run at different Cloudflare edge locations.

CREATE TABLE IF NOT EXISTS oauth_webauthn_challenges (
  challenge_id TEXT NOT NULL UNIQUE,
  user_id TEXT NOT NULL,
  challenge TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  consumed_at INTEGER,
  CHECK (expires_at > created_at),
  CHECK (consumed_at IS NULL OR consumed_at >= created_at)
);

CREATE INDEX IF NOT EXISTS idx_oauth_webauthn_challenges_lookup
  ON oauth_webauthn_challenges (challenge_id, user_id, expires_at, consumed_at);

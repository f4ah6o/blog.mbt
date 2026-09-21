///|
/// OAuth WebAuthn challenges must be readable by the verify request even when
/// Cloudflare routes authorize and verify to different edge locations. D1 is
/// used for this short-lived, one-time value because KV is eventually
/// consistent across locations.
pub const OAUTH_WEBAUTHN_CHALLENGE_TTL_SECONDS : Int = 300

///|
extern "js" fn insert_oauth_webauthn_challenge_js(
  db : @core.Any,
  challenge_id : String,
  user_id : String,
  challenge : String,
  created_at : Int,
  expires_at : Int,
) -> @core.Promise[Bool] =
  #| async (db, challengeId, userId, challenge, createdAt, expiresAt) => {
  #|   try {
  #|     const result = await db
  #|       .prepare("INSERT INTO oauth_webauthn_challenges (challenge_id, user_id, challenge, created_at, expires_at) VALUES (?, ?, ?, ?, ?)")
  #|       .bind(challengeId, userId, challenge, createdAt, expiresAt)
  #|       .run();
  #|     return Boolean(result && result.success !== false);
  #|   } catch (_) {
  #|     return false;
  #|   }
  #| }

///|
extern "js" fn claim_oauth_webauthn_challenge_js(
  db : @core.Any,
  challenge_id : String,
  user_id : String,
  now : Int,
) -> @core.Promise[String?] =
  #| async (db, challengeId, userId, now) => {
  #|   try {
  #|     const row = await db
  #|       .prepare("UPDATE oauth_webauthn_challenges SET consumed_at = ? WHERE challenge_id = ? AND user_id = ? AND expires_at > ? AND consumed_at IS NULL RETURNING challenge")
  #|       .bind(now, challengeId, userId, now)
  #|       .first();
  #|     return row && row.challenge !== undefined ? String(row.challenge) : undefined;
  #|   } catch (_) {
  #|     return undefined;
  #|   }
  #| }

///|
extern "js" fn delete_oauth_webauthn_challenge_js(
  db : @core.Any,
  challenge_id : String,
  user_id : String,
) -> @core.Promise[Unit] =
  #| async (db, challengeId, userId) => {
  #|   try {
  #|     await db
  #|       .prepare("DELETE FROM oauth_webauthn_challenges WHERE challenge_id = ? AND user_id = ?")
  #|       .bind(challengeId, userId)
  #|       .run();
  #|   } catch (_) {}
  #| }

///|
pub async fn insert_oauth_webauthn_challenge(
  db : @cloudflare.D1Database,
  challenge_id : String,
  user_id : String,
  challenge : String,
  created_at : Int,
  expires_at : Int,
) -> Bool {
  insert_oauth_webauthn_challenge_js(
    db.as_any(),
    challenge_id,
    user_id,
    challenge,
    created_at,
    expires_at,
  ).wait() catch {
    _ => false
  }
}

///|
pub async fn claim_oauth_webauthn_challenge(
  db : @cloudflare.D1Database,
  challenge_id : String,
  user_id : String,
  now : Int,
) -> String? {
  claim_oauth_webauthn_challenge_js(db.as_any(), challenge_id, user_id, now).wait() catch {
    _ => None
  }
}

///|
pub async fn delete_oauth_webauthn_challenge(
  db : @cloudflare.D1Database,
  challenge_id : String,
  user_id : String,
) -> Unit {
  delete_oauth_webauthn_challenge_js(db.as_any(), challenge_id, user_id).wait()
}

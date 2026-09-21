///|
/// Pending authorizations are short-lived bindings between a WebAuthn
/// challenge and an already-validated OAuth authorization request. They are
/// persisted in D1 (BLOG_DB) and keyed by the server-generated, non-secret
/// challenge identifier, so the one-time claim can be a single conditional
/// UPDATE rather than an eventually-consistent KV get/delete.
pub const PENDING_AUTHORIZATION_TTL_SECONDS : Int = 300

///|
/// A short-lived server-side binding between a WebAuthn challenge and an
/// already-validated OAuth authorization request. The representation is
/// private so the raw request fields cannot be tampered with between the
/// authorization page and the verify POST.
pub struct PendingAuthorization {
  challenge_id : String
  user_id : String
  request : AuthorizationRequest
  created_at : Int
  expires_at : Int
}

///|
/// Build the pending authorization at the moment the WebAuthn challenge is
/// created. Missing bindings or a non-positive lifetime fail closed.
pub fn pending_authorization(
  challenge_id : String,
  user_id : String,
  request : AuthorizationRequest,
  now : Int,
  lifetime_seconds : Int,
) -> PendingAuthorization? {
  if challenge_id.is_empty() || user_id.is_empty() || lifetime_seconds <= 0 {
    return None
  }
  Some(PendingAuthorization::{
    challenge_id,
    user_id,
    request,
    created_at: now,
    expires_at: now + lifetime_seconds,
  })
}

///|
pub fn PendingAuthorization::challenge_identifier(
  self : PendingAuthorization,
) -> String {
  self.challenge_id
}

///|
pub fn PendingAuthorization::expiry(self : PendingAuthorization) -> Int {
  self.expires_at
}

///|
pub fn PendingAuthorization::bound_request(
  self : PendingAuthorization,
) -> AuthorizationRequest {
  self.request
}

///|
fn pending_state_or_null(value : String?) -> @core.Any {
  match value {
    Some(state) => @core.any(state)
    None => @core.null()
  }
}

///|
extern "js" fn insert_pending_authorization_js(
  db : @core.Any,
  challenge_id : String,
  user_id : String,
  client_id : String,
  redirect_uri : String,
  resource : String,
  scope : String,
  code_challenge : String,
  code_challenge_method : String,
  state : @core.Any,
  created_at : Int,
  expires_at : Int,
) -> @core.Promise[String] =
  #| async (db, challengeId, userId, clientId, redirectUri, resource, scope, codeChallenge, codeChallengeMethod, state, createdAt, expiresAt) => {
  #|   try {
  #|     const result = await db
  #|       .prepare("INSERT INTO oauth_pending_authorizations (challenge_id, user_id, client_id, redirect_uri, resource, scope, code_challenge, code_challenge_method, state, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
  #|       .bind(challengeId, userId, clientId, redirectUri, resource, scope, codeChallenge, codeChallengeMethod, state, createdAt, expiresAt)
  #|       .run();
  #|     if (!result || result.success === false) return result?.error || "d1_write_failed";
  #|     return "";
  #|   } catch (error) {
  #|     return String(error && error.message ? error.message : error);
  #|   }
  #| }

///|
/// Persist the already-validated binding before the authorization page is
/// returned. The caller fails closed and drops the WebAuthn challenge if this
/// write does not succeed.
pub async fn insert_pending_authorization(
  db : @cloudflare.D1Database,
  pending : PendingAuthorization,
) -> String {
  insert_pending_authorization_js(
    db.as_any(),
    pending.challenge_id,
    pending.user_id,
    pending.request.client_id,
    pending.request.redirect_uri,
    pending.request.resource,
    pending.request.scope,
    pending.request.code_challenge,
    pending.request.code_challenge_method,
    pending_state_or_null(pending.request.state),
    pending.created_at,
    pending.expires_at,
  ).wait() catch {
    _ => "d1_write_failed"
  }
}

///|
/// Pure mirror of the conditional UPDATE predicate. A concurrent or replayed
/// claim observes a consumed row (or no row) and fails closed.
pub fn pending_claim_is_allowed(
  matches : Bool,
  consumed_at : Int?,
  expires_at : Int,
  now : Int,
) -> Bool {
  matches && consumed_at is None && is_unexpired(expires_at, now)
}

///|
/// D1's MoonBit wrapper can raise while reading a returned row in the Worker
/// runtime. Keep this adapter thin and use the native D1 object directly,
/// while leaving all request reconstruction and validation in MoonBit.
extern "js" fn claim_pending_authorization_js(
  db : @core.Any,
  challenge_id : String,
  user_id : String,
  now : Int,
) -> @core.Promise[String?] =
  #| async (db, challengeId, userId, now) => {
  #|   try {
  #|     const row = await db
  #|       .prepare("SELECT client_id, redirect_uri, resource, scope, code_challenge, code_challenge_method, state FROM oauth_pending_authorizations WHERE challenge_id = ? AND user_id = ? AND expires_at > ? AND consumed_at IS NULL")
  #|       .bind(challengeId, userId, now)
  #|       .first();
  #|     if (!row) return undefined;
  #|     const result = await db
  #|       .prepare("UPDATE oauth_pending_authorizations SET consumed_at = ? WHERE challenge_id = ? AND user_id = ? AND expires_at > ? AND consumed_at IS NULL")
  #|       .bind(now, challengeId, userId, now)
  #|       .run();
  #|     if (!result || result.success === false || result.meta?.changes !== 1) {
  #|       return undefined;
  #|     }
  #|     return JSON.stringify({
  #|       client_id: row.client_id,
  #|       redirect_uri: row.redirect_uri,
  #|       resource: row.resource,
  #|       scope: row.scope,
  #|       code_challenge: row.code_challenge,
  #|       code_challenge_method: row.code_challenge_method,
  #|       state: row.state === null || row.state === undefined ? null : row.state,
  #|     });
  #|   } catch (_) {
  #|     return undefined;
  #|   }
  #| }

///|
/// Atomically claim the pending authorization after WebAuthn has been verified.
/// The conditional UPDATE is the single-use gate: a replay or an expired row
/// returns no request.
pub async fn claim_pending_authorization(
  db : @cloudflare.D1Database,
  challenge_id : String,
  user_id : String,
  now : Int,
) -> AuthorizationRequest? {
  let raw = claim_pending_authorization_js(
    db.as_any(),
    challenge_id,
    user_id,
    now,
  ).wait() catch {
    _ => None
  }
  match raw {
    Some(value) => AuthorizationRequest::from_json_string(value)
    None => None
  }
}

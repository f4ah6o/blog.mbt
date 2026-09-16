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
fn pending_row_optional_string(row : @core.Any, key : String) -> String? {
  let value = row[key]
  if @core.typeof_(value) == "undefined" || @core.is_null(value) {
    None
  } else {
    Some(value.cast())
  }
}

///|
/// Persist the already-validated binding before the authorization page is
/// returned. The caller fails closed and drops the WebAuthn challenge if this
/// write does not succeed.
pub async fn insert_pending_authorization(
  db : @cloudflare.D1Database,
  pending : PendingAuthorization,
) -> Unit raise @cloudflare.D1Error {
  db
  .prepare(
    "INSERT INTO oauth_pending_authorizations (challenge_id, user_id, client_id, redirect_uri, resource, scope, code_challenge, code_challenge_method, state, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
  )
  .bind([
    @core.any(pending.challenge_id),
    @core.any(pending.user_id),
    @core.any(pending.request.client_id),
    @core.any(pending.request.redirect_uri),
    @core.any(pending.request.resource),
    @core.any(pending.request.scope),
    @core.any(pending.request.code_challenge),
    @core.any(pending.request.code_challenge_method),
    pending_state_or_null(pending.request.state),
    @core.any(pending.created_at),
    @core.any(pending.expires_at),
  ])
  .run()
  |> ignore
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
/// Atomically claim the pending authorization after WebAuthn has been verified.
/// The conditional UPDATE is the single-use gate: two concurrent callers cannot
/// both observe a successful change count, and an expired, missing, or already
/// consumed row fails closed. The validated request is only returned to the
/// caller that won the claim.
pub async fn claim_pending_authorization(
  db : @cloudflare.D1Database,
  challenge_id : String,
  user_id : String,
  now : Int,
) -> AuthorizationRequest? raise @cloudflare.D1Error {
  let row = db
    .prepare(
      "SELECT client_id, redirect_uri, resource, scope, code_challenge, code_challenge_method, state FROM oauth_pending_authorizations WHERE challenge_id = ? AND user_id = ? AND expires_at > ? AND consumed_at IS NULL",
    )
    .bind([@core.any(challenge_id), @core.any(user_id), @core.any(now)])
    .first()
  let request = match row {
    None => return None
    Some(value) =>
      AuthorizationRequest::{
        client_id: value["client_id"].cast(),
        redirect_uri: value["redirect_uri"].cast(),
        resource: value["resource"].cast(),
        scope: value["scope"].cast(),
        code_challenge: value["code_challenge"].cast(),
        code_challenge_method: value["code_challenge_method"].cast(),
        state: pending_row_optional_string(value, "state"),
      }
  }
  let result = db
    .prepare(
      "UPDATE oauth_pending_authorizations SET consumed_at = ? WHERE challenge_id = ? AND user_id = ? AND expires_at > ? AND consumed_at IS NULL",
    )
    .bind([
      @core.any(now),
      @core.any(challenge_id),
      @core.any(user_id),
      @core.any(now),
    ])
    .run()
  if changed_rows(result) == 1 {
    Some(request)
  } else {
    None
  }
}

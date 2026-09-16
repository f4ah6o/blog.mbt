///|
pub struct AuthorizationCodeRecord {
  code_hash : String
  client_id : String
  redirect_uri : String
  resource : String
  scope : String
  code_challenge : String
  code_challenge_method : String
  created_at : Int
  expires_at : Int
}

///|
pub fn authorization_code_record(
  code_hash : String,
  client_id : String,
  redirect_uri : String,
  resource : String,
  scope : String,
  code_challenge : String,
  code_challenge_method : String,
  created_at : Int,
  expires_at : Int,
) -> AuthorizationCodeRecord? {
  if !validate_sha256_hex(code_hash) ||
    client_id.is_empty() ||
    redirect_uri.is_empty() ||
    resource.is_empty() ||
    !validate_scope(scope) ||
    !validate_pkce_challenge(code_challenge) ||
    code_challenge_method != "S256" ||
    expires_at <= created_at {
    return None
  }
  Some(AuthorizationCodeRecord::{
    code_hash,
    client_id,
    redirect_uri,
    resource,
    scope,
    code_challenge,
    code_challenge_method,
    created_at,
    expires_at,
  })
}

///|
pub struct AccessTokenRecord {
  token_hash : String
  client_id : String
  resource : String
  scope : String
  created_at : Int
  expires_at : Int
}

///|
pub fn access_token_record(
  token_hash : String,
  client_id : String,
  resource : String,
  scope : String,
  created_at : Int,
  expires_at : Int,
) -> AccessTokenRecord? {
  if !validate_sha256_hex(token_hash) ||
    client_id.is_empty() ||
    resource.is_empty() ||
    !validate_scope(scope) ||
    expires_at <= created_at {
    return None
  }
  Some(AccessTokenRecord::{
    token_hash,
    client_id,
    resource,
    scope,
    created_at,
    expires_at,
  })
}

///|
pub struct RefreshTokenRecord {
  token_hash : String
  family_hash : String
  client_id : String
  resource : String
  scope : String
  created_at : Int
  expires_at : Int
}

///|
pub fn refresh_token_record(
  token_hash : String,
  family_hash : String,
  client_id : String,
  resource : String,
  scope : String,
  created_at : Int,
  expires_at : Int,
) -> RefreshTokenRecord? {
  if !validate_sha256_hex(token_hash) ||
    !validate_sha256_hex(family_hash) ||
    client_id.is_empty() ||
    resource.is_empty() ||
    !validate_scope(scope) ||
    expires_at <= created_at {
    return None
  }
  Some(RefreshTokenRecord::{
    token_hash,
    family_hash,
    client_id,
    resource,
    scope,
    created_at,
    expires_at,
  })
}

///|
pub(all) enum RedeemAuthorizationCodeResult {
  AuthorizationCodeRedeemed(String)
  AuthorizationCodeInvalid
} derive(Debug, Eq)

///|
fn changed_rows(result : @cloudflare.D1Result) -> Int {
  match result.meta() {
    Some(meta) => meta.changes().unwrap_or(0)
    None => 0
  }
}

///|
pub async fn insert_authorization_code(
  db : @cloudflare.D1Database,
  record : AuthorizationCodeRecord,
) -> Unit raise @cloudflare.D1Error {
  db
  .prepare(
    "INSERT INTO oauth_authorization_codes (code_hash, client_id, redirect_uri, resource, scope, code_challenge, code_challenge_method, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
  )
  .bind([
    @core.any(record.code_hash),
    @core.any(record.client_id),
    @core.any(record.redirect_uri),
    @core.any(record.resource),
    @core.any(record.scope),
    @core.any(record.code_challenge),
    @core.any(record.code_challenge_method),
    @core.any(record.created_at),
    @core.any(record.expires_at),
  ])
  .run()
  |> ignore
}

///|
/// The conditional update is the single-use claim. Two concurrent callers
/// cannot both observe a successful change count.
pub async fn redeem_authorization_code(
  db : @cloudflare.D1Database,
  code_hash : String,
  client_id : String,
  redirect_uri : String,
  resource : String,
  code_verifier : String,
  now : Int,
) -> RedeemAuthorizationCodeResult raise @cloudflare.D1Error {
  if !validate_pkce_verifier(code_verifier) {
    return AuthorizationCodeInvalid
  }
  let row = db
    .prepare(
      "SELECT scope, code_challenge FROM oauth_authorization_codes WHERE code_hash = ? AND client_id = ? AND redirect_uri = ? AND resource = ? AND code_challenge_method = 'S256' AND expires_at > ? AND consumed_at IS NULL",
    )
    .bind([
      @core.any(code_hash),
      @core.any(client_id),
      @core.any(redirect_uri),
      @core.any(resource),
      @core.any(now),
    ])
    .first()
  let (scope, code_challenge) : (String, String) = match row {
    Some(value) => (value["scope"].cast(), value["code_challenge"].cast())
    None => return AuthorizationCodeInvalid
  }
  let pkce_valid = verify_pkce_s256(code_challenge, code_verifier) catch {
    _ => false
  }
  if !pkce_valid {
    return AuthorizationCodeInvalid
  }
  let result = db
    .prepare(
      "UPDATE oauth_authorization_codes SET consumed_at = ? WHERE code_hash = ? AND client_id = ? AND redirect_uri = ? AND resource = ? AND code_challenge = ? AND code_challenge_method = 'S256' AND expires_at > ? AND consumed_at IS NULL",
    )
    .bind([
      @core.any(now),
      @core.any(code_hash),
      @core.any(client_id),
      @core.any(redirect_uri),
      @core.any(resource),
      @core.any(code_challenge),
      @core.any(now),
    ])
    .run()
  if changed_rows(result) == 1 {
    AuthorizationCodeRedeemed(scope)
  } else {
    AuthorizationCodeInvalid
  }
}

///|
pub async fn insert_access_token(
  db : @cloudflare.D1Database,
  record : AccessTokenRecord,
) -> Unit raise @cloudflare.D1Error {
  db
  .prepare(
    "INSERT INTO oauth_access_tokens (token_hash, client_id, resource, scope, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?)",
  )
  .bind([
    @core.any(record.token_hash),
    @core.any(record.client_id),
    @core.any(record.resource),
    @core.any(record.scope),
    @core.any(record.created_at),
    @core.any(record.expires_at),
  ])
  .run()
  |> ignore
}

///|
pub async fn lookup_access_token(
  db : @cloudflare.D1Database,
  token_hash : String,
  resource : String,
  required_scope : String,
  now : Int,
) -> AccessTokenRecord? raise @cloudflare.D1Error {
  let row = db
    .prepare(
      "SELECT token_hash, client_id, resource, scope, created_at, expires_at FROM oauth_access_tokens WHERE token_hash = ? AND resource = ? AND expires_at > ? AND revoked_at IS NULL",
    )
    .bind([@core.any(token_hash), @core.any(resource), @core.any(now)])
    .first()
  match row {
    None => None
    Some(value) => {
      let scope : String = value["scope"].cast()
      if !validate_scope(scope) || !scope_contains(scope, required_scope) {
        None
      } else {
        Some(AccessTokenRecord::{
          token_hash: value["token_hash"].cast(),
          client_id: value["client_id"].cast(),
          resource: value["resource"].cast(),
          scope,
          created_at: @cloudflare.js_number_to_int(value["created_at"]),
          expires_at: @cloudflare.js_number_to_int(value["expires_at"]),
        })
      }
    }
  }
}

///|
pub async fn revoke_access_token(
  db : @cloudflare.D1Database,
  token_hash : String,
  client_id : String,
  resource : String,
  now : Int,
) -> Unit raise @cloudflare.D1Error {
  db
  .prepare(
    "UPDATE oauth_access_tokens SET revoked_at = ? WHERE token_hash = ? AND client_id = ? AND resource = ? AND expires_at > ? AND revoked_at IS NULL",
  )
  .bind([
    @core.any(now),
    @core.any(token_hash),
    @core.any(client_id),
    @core.any(resource),
    @core.any(now),
  ])
  .run()
  |> ignore
}

///|
pub async fn insert_refresh_token(
  db : @cloudflare.D1Database,
  record : RefreshTokenRecord,
) -> Unit raise @cloudflare.D1Error {
  db
  .prepare(
    "INSERT INTO oauth_refresh_tokens (token_hash, family_hash, client_id, resource, scope, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
  )
  .bind([
    @core.any(record.token_hash),
    @core.any(record.family_hash),
    @core.any(record.client_id),
    @core.any(record.resource),
    @core.any(record.scope),
    @core.any(record.created_at),
    @core.any(record.expires_at),
  ])
  .run()
  |> ignore
}

///|
/// D1 batch transactions make the old-token claim and replacement insert one
/// unit. A later lookup only classifies a failed claim as replay when the old
/// row is visibly consumed; callers can then revoke the family.
pub async fn rotate_refresh_token(
  db : @cloudflare.D1Database,
  old_token_hash : String,
  client_id : String,
  resource : String,
  replacement_token_hash : String,
  replacement_created_at : Int,
  replacement_expires_at : Int,
  now : Int,
) -> RefreshRotationDecision raise @cloudflare.D1Error {
  let update = db
    .prepare(
      "UPDATE oauth_refresh_tokens SET consumed_at = ?, replacement_token_hash = ? WHERE token_hash = ? AND client_id = ? AND resource = ? AND expires_at > ? AND consumed_at IS NULL AND revoked_at IS NULL",
    )
    .bind([
      @core.any(now),
      @core.any(replacement_token_hash),
      @core.any(old_token_hash),
      @core.any(client_id),
      @core.any(resource),
      @core.any(now),
    ])
  let insert = db
    .prepare(
      "INSERT INTO oauth_refresh_tokens (token_hash, family_hash, client_id, resource, scope, created_at, expires_at) SELECT ?, family_hash, client_id, resource, scope, ?, ? FROM oauth_refresh_tokens WHERE token_hash = ? AND client_id = ? AND resource = ? AND consumed_at = ? AND replacement_token_hash = ?",
    )
    .bind([
      @core.any(replacement_token_hash),
      @core.any(replacement_created_at),
      @core.any(replacement_expires_at),
      @core.any(old_token_hash),
      @core.any(client_id),
      @core.any(resource),
      @core.any(now),
      @core.any(replacement_token_hash),
    ])
  let results = db.batch([update, insert])
  if results.length() == 2 &&
    changed_rows(results[0]) == 1 &&
    changed_rows(results[1]) == 1 {
    RefreshRotated
  } else {
    let row = db
      .prepare(
        "SELECT consumed_at FROM oauth_refresh_tokens WHERE token_hash = ? AND client_id = ? AND resource = ?",
      )
      .bind([
        @core.any(old_token_hash),
        @core.any(client_id),
        @core.any(resource),
      ])
      .first()
    match row {
      Some(value) if !@core.is_null(value["consumed_at"]) => RefreshReplay
      _ => RefreshInvalid
    }
  }
}

///|
/// Safe follow-up for a detected replay: revoke every token in the family.
pub async fn revoke_refresh_family(
  db : @cloudflare.D1Database,
  family_hash : String,
  now : Int,
) -> Unit raise @cloudflare.D1Error {
  db
  .prepare(
    "UPDATE oauth_refresh_tokens SET revoked_at = ? WHERE family_hash = ? AND revoked_at IS NULL",
  )
  .bind2(@core.any(now), @core.any(family_hash))
  .run()
  |> ignore
}

///|
/// Revoke the full refresh-token family after replay detection without
/// exposing the family identifier to the endpoint layer.
pub async fn revoke_refresh_family_for_token(
  db : @cloudflare.D1Database,
  token_hash : String,
  client_id : String,
  resource : String,
  now : Int,
) -> Unit raise @cloudflare.D1Error {
  db
  .prepare(
    "UPDATE oauth_refresh_tokens SET revoked_at = ? WHERE family_hash = (SELECT family_hash FROM oauth_refresh_tokens WHERE token_hash = ? AND client_id = ? AND resource = ?) AND revoked_at IS NULL",
  )
  .bind([
    @core.any(now),
    @core.any(token_hash),
    @core.any(client_id),
    @core.any(resource),
  ])
  .run()
  |> ignore
}

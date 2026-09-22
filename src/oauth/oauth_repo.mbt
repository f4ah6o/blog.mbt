///|
/// Storage-layer failure raised by the native D1 adapters in this module.
/// Mirrors `mizchi/cloudflare.D1Error`, which is read-only outside its package
/// and so cannot be constructed here.
pub suberror OAuthStorageError {
  OAuthStorageError(String)
}

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
} derive(Debug, Eq)

///|
pub fn AccessTokenRecord::client_id(self : AccessTokenRecord) -> String {
  self.client_id
}

///|
pub fn AccessTokenRecord::resource(self : AccessTokenRecord) -> String {
  self.resource
}

///|
pub fn AccessTokenRecord::scope(self : AccessTokenRecord) -> String {
  self.scope
}

///|
pub fn AccessTokenRecord::expires_at(self : AccessTokenRecord) -> Int {
  self.expires_at
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
pub fn RefreshTokenRecord::scope(self : RefreshTokenRecord) -> String {
  self.scope
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
struct AuthorizationCodeScopeRow {
  scope : String
  code_challenge : String
} derive(FromJson)

///|
struct AccessTokenRow {
  token_hash : String
  client_id : String
  resource : String
  scope : String
  created_at : Int
  expires_at : Int
} derive(FromJson)

///|
fn changed_rows(result : @cloudflare.D1Result) -> Int {
  match result.meta() {
    Some(meta) => meta.changes().unwrap_or(0)
    None => 0
  }
}

///|
extern "js" fn insert_authorization_code_js(
  db : @core.Any,
  code_hash : String,
  client_id : String,
  redirect_uri : String,
  resource : String,
  scope : String,
  code_challenge : String,
  code_challenge_method : String,
  created_at : Int,
  expires_at : Int,
) -> @core.Promise[Bool] =
  #| async (db, codeHash, clientId, redirectUri, resource, scope, codeChallenge, codeChallengeMethod, createdAt, expiresAt) => {
  #|   try {
  #|     const result = await db
  #|       .prepare("INSERT INTO oauth_authorization_codes (code_hash, client_id, redirect_uri, resource, scope, code_challenge, code_challenge_method, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")
  #|       .bind(codeHash, clientId, redirectUri, resource, scope, codeChallenge, codeChallengeMethod, createdAt, expiresAt)
  #|       .run();
  #|     return Boolean(result && result.success !== false);
  #|   } catch (_) {
  #|     return false;
  #|   }
  #| }

///|
/// Read the stored authorization-code binding through the native D1 object.
/// The MoonBit D1 wrapper's row conversion can raise in the Worker runtime;
/// protocol validation remains in MoonBit after this adapter returns JSON.
extern "js" fn authorization_code_scope_js(
  db : @core.Any,
  code_hash : String,
  client_id : String,
  redirect_uri : String,
  resource : String,
  now : Int,
) -> @core.Promise[String?] =
  #| async (db, codeHash, clientId, redirectUri, resource, now) => {
  #|   try {
  #|     const row = await db
  #|       .prepare("SELECT scope, code_challenge FROM oauth_authorization_codes WHERE code_hash = ? AND client_id = ? AND redirect_uri = ? AND resource = ? AND code_challenge_method = 'S256' AND expires_at > ? AND consumed_at IS NULL")
  #|       .bind(codeHash, clientId, redirectUri, resource, now)
  #|       .first();
  #|     if (!row) return undefined;
  #|     return JSON.stringify({
  #|       scope: row.scope,
  #|       code_challenge: row.code_challenge,
  #|     });
  #|   } catch (_) {
  #|     return undefined;
  #|   }
  #| }

///|
async fn authorization_code_scope_row(
  db : @core.Any,
  code_hash : String,
  client_id : String,
  redirect_uri : String,
  resource : String,
  now : Int,
) -> (String, String)? {
  let raw = authorization_code_scope_js(
    db, code_hash, client_id, redirect_uri, resource, now,
  ).wait() catch {
    _ => None
  }
  match raw {
    None => None
    Some(value) => {
      let json = @json.parse(value) catch { _ => return None }
      let row : AuthorizationCodeScopeRow = @json.from_json(json) catch {
        _ => return None
      }
      Some((row.scope, row.code_challenge))
    }
  }
}

///|
pub async fn insert_authorization_code(
  db : @cloudflare.D1Database,
  record : AuthorizationCodeRecord,
) -> Unit {
  let ok = insert_authorization_code_js(
    db.as_any(),
    record.code_hash,
    record.client_id,
    record.redirect_uri,
    record.resource,
    record.scope,
    record.code_challenge,
    record.code_challenge_method,
    record.created_at,
    record.expires_at,
  ).wait() catch {
    _ => false
  }
  if !ok {
    fail("d1_write_failed")
  }
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
/// Read and validate the stored authorization-code binding without claiming it.
/// The claim is performed only by redeem_authorization_code_with_tokens.
pub async fn authorization_code_scope(
  db : @cloudflare.D1Database,
  code_hash : String,
  client_id : String,
  redirect_uri : String,
  resource : String,
  code_verifier : String,
  now : Int,
) -> String? {
  if !validate_pkce_verifier(code_verifier) {
    return None
  }
  let row = authorization_code_scope_row(
    db.as_any(),
    code_hash,
    client_id,
    redirect_uri,
    resource,
    now,
  )
  match row {
    Some((scope, challenge)) => {
      let valid = verify_pkce_s256(challenge, code_verifier) catch {
        _ => false
      }
      if valid {
        Some(scope)
      } else {
        None
      }
    }
    None => None
  }
}

///|
/// Claim an authorization code and persist all issued token rows in one D1
/// batch. The INSERT predicates repeat the exact code binding and only match
/// the row after the conditional claim has succeeded.
extern "js" fn redeem_authorization_code_with_tokens_js(
  db : @core.Any,
  code_hash : String,
  client_id : String,
  redirect_uri : String,
  resource : String,
  scope : String,
  challenge : String,
  now : Int,
  access_token_hash : String,
  access_client_id : String,
  access_resource : String,
  access_scope : String,
  access_created_at : Int,
  access_expires_at : Int,
  has_refresh : Bool,
  refresh_token_hash : String,
  refresh_family_hash : String,
  refresh_client_id : String,
  refresh_resource : String,
  refresh_scope : String,
  refresh_created_at : Int,
  refresh_expires_at : Int,
) -> @core.Promise[Int] =
  #| async (db, codeHash, clientId, redirectUri, resource, scope, challenge, now, accessTokenHash, accessClientId, accessResource, accessScope, accessCreatedAt, accessExpiresAt, hasRefresh, refreshTokenHash, refreshFamilyHash, refreshClientId, refreshResource, refreshScope, refreshCreatedAt, refreshExpiresAt) => {
  #|   try {
  #|     const claim = db
  #|       .prepare("UPDATE oauth_authorization_codes SET consumed_at = ? WHERE code_hash = ? AND client_id = ? AND redirect_uri = ? AND resource = ? AND scope = ? AND code_challenge = ? AND code_challenge_method = 'S256' AND expires_at > ? AND consumed_at IS NULL")
  #|       .bind(now, codeHash, clientId, redirectUri, resource, scope, challenge, now);
  #|     const accessInsert = db
  #|       .prepare("INSERT INTO oauth_access_tokens (token_hash, client_id, resource, scope, created_at, expires_at) SELECT ?, ?, ?, ?, ?, ? WHERE changes() = 1 AND EXISTS (SELECT 1 FROM oauth_authorization_codes WHERE code_hash = ? AND client_id = ? AND redirect_uri = ? AND resource = ? AND scope = ? AND code_challenge = ? AND consumed_at = ?)")
  #|       .bind(accessTokenHash, accessClientId, accessResource, accessScope, accessCreatedAt, accessExpiresAt, codeHash, clientId, redirectUri, resource, scope, challenge, now);
  #|     const statements = [claim, accessInsert];
  #|     if (hasRefresh) {
  #|       statements.push(
  #|         db
  #|           .prepare("INSERT INTO oauth_refresh_tokens (token_hash, family_hash, client_id, resource, scope, created_at, expires_at) SELECT ?, ?, ?, ?, ?, ?, ? WHERE changes() = 1 AND EXISTS (SELECT 1 FROM oauth_authorization_codes WHERE code_hash = ? AND client_id = ? AND redirect_uri = ? AND resource = ? AND scope = ? AND code_challenge = ? AND consumed_at = ?)")
  #|           .bind(refreshTokenHash, refreshFamilyHash, refreshClientId, refreshResource, refreshScope, refreshCreatedAt, refreshExpiresAt, codeHash, clientId, redirectUri, resource, scope, challenge, now),
  #|       );
  #|     }
  #|     const results = await db.batch(statements);
  #|     const expected = hasRefresh ? 3 : 2;
  #|     if (!results || results.length !== expected) return -1;
  #|     if (!results[0] || results[0].success === false || results[0].meta?.changes !== 1) return 0;
  #|     if (!results[1] || results[1].success === false || results[1].meta?.changes !== 1) return -1;
  #|     if (hasRefresh && (!results[2] || results[2].success === false || results[2].meta?.changes !== 1)) return -1;
  #|     return 1;
  #|   } catch (_) {
  #|     return -1;
  #|   }
  #| }

///|
pub async fn redeem_authorization_code_with_tokens(
  db : @cloudflare.D1Database,
  code_hash : String,
  client_id : String,
  redirect_uri : String,
  resource : String,
  code_verifier : String,
  now : Int,
  access : AccessTokenRecord,
  refresh : RefreshTokenRecord?,
) -> RedeemAuthorizationCodeResult {
  if !validate_pkce_verifier(code_verifier) {
    return AuthorizationCodeInvalid
  }
  let (scope, challenge) = match
    authorization_code_scope_row(
      db.as_any(),
      code_hash,
      client_id,
      redirect_uri,
      resource,
      now,
    ) {
    Some(value) => value
    None => return AuthorizationCodeInvalid
  }
  let pkce_valid = verify_pkce_s256(challenge, code_verifier) catch {
    _ => false
  }
  if !pkce_valid ||
    scope != access.scope ||
    access.client_id != client_id ||
    access.resource != resource {
    return AuthorizationCodeInvalid
  }
  let wants_refresh = scope_contains(scope, SCOPE_OFFLINE_ACCESS)
  match refresh {
    Some(record) =>
      if !wants_refresh ||
        record.client_id != client_id ||
        record.resource != resource ||
        record.scope != scope {
        return AuthorizationCodeInvalid
      }
    None => if wants_refresh { return AuthorizationCodeInvalid }
  }
  let (
    has_refresh,
    refresh_token_hash,
    refresh_family_hash,
    refresh_client_id,
    refresh_resource,
    refresh_scope,
    refresh_created_at,
    refresh_expires_at,
  ) = match refresh {
    Some(record) =>
      (
        true,
        record.token_hash,
        record.family_hash,
        record.client_id,
        record.resource,
        record.scope,
        record.created_at,
        record.expires_at,
      )
    None => (false, "", "", "", "", "", 0, 0)
  }
  let result = redeem_authorization_code_with_tokens_js(
    db.as_any(),
    code_hash,
    client_id,
    redirect_uri,
    resource,
    scope,
    challenge,
    now,
    access.token_hash,
    access.client_id,
    access.resource,
    access.scope,
    access.created_at,
    access.expires_at,
    has_refresh,
    refresh_token_hash,
    refresh_family_hash,
    refresh_client_id,
    refresh_resource,
    refresh_scope,
    refresh_created_at,
    refresh_expires_at,
  ).wait() catch {
    _ => -1
  }
  if result == 1 {
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
/// Read an access-token row through native D1 for the Worker runtime.
extern "js" fn lookup_access_token_js(
  db : @core.Any,
  token_hash : String,
  resource : String,
  now : Int,
) -> @core.Promise[String?] =
  #| async (db, tokenHash, resource, now) => {
  #|   try {
  #|     const row = await db
  #|       .prepare("SELECT token_hash, client_id, resource, scope, created_at, expires_at FROM oauth_access_tokens WHERE token_hash = ? AND resource = ? AND expires_at > ? AND revoked_at IS NULL")
  #|       .bind(tokenHash, resource, now)
  #|       .first();
  #|     if (!row) return undefined;
  #|     return JSON.stringify({
  #|       token_hash: row.token_hash,
  #|       client_id: row.client_id,
  #|       resource: row.resource,
  #|       scope: row.scope,
  #|       created_at: row.created_at,
  #|       expires_at: row.expires_at,
  #|     });
  #|   } catch (_) {
  #|     return undefined;
  #|   }
  #| }

///|
async fn lookup_access_token_row(
  db : @core.Any,
  token_hash : String,
  resource : String,
  now : Int,
) -> AccessTokenRecord? {
  let raw = lookup_access_token_js(db, token_hash, resource, now).wait() catch {
    _ => None
  }
  match raw {
    None => None
    Some(value) => {
      let json = @json.parse(value) catch { _ => return None }
      let row : AccessTokenRow = @json.from_json(json) catch {
        _ => return None
      }
      access_token_record(
        row.token_hash,
        row.client_id,
        row.resource,
        row.scope,
        row.created_at,
        row.expires_at,
      )
    }
  }
}

///|
pub async fn lookup_access_token(
  db : @cloudflare.D1Database,
  token_hash : String,
  resource : String,
  required_scope : String,
  now : Int,
) -> AccessTokenRecord? {
  match lookup_access_token_row(db.as_any(), token_hash, resource, now) {
    None => None
    Some(record) =>
      if !scope_contains(record.scope, required_scope) {
        None
      } else {
        Some(record)
      }
  }
}

///|
/// Validate a bearer token independently from authorization scope. Keeping
/// this result separate lets the resource server return 403 for a valid token
/// that lacks permission instead of misreporting it as an invalid token.
pub async fn lookup_access_token_for_resource(
  db : @cloudflare.D1Database,
  token_hash : String,
  resource : String,
  now : Int,
) -> AccessTokenRecord? {
  if !validate_sha256_hex(token_hash) || resource.is_empty() {
    return None
  }
  lookup_access_token_row(db.as_any(), token_hash, resource, now)
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
/// Read a refresh-token row through the native D1 object for the Worker
/// runtime. Returns "err" on a storage failure so the caller can tell a
/// backend error apart from a missing row.
extern "js" fn lookup_refresh_token_js(
  db : @core.Any,
  token_hash : String,
  client_id : String,
  resource : String,
  now : Int,
) -> @core.Promise[String?] =
  #| async (db, tokenHash, clientId, resource, now) => {
  #|   try {
  #|     const row = await db
  #|       .prepare("SELECT token_hash, family_hash, client_id, resource, scope, created_at, expires_at FROM oauth_refresh_tokens WHERE token_hash = ? AND client_id = ? AND resource = ? AND expires_at > ? AND consumed_at IS NULL AND revoked_at IS NULL")
  #|       .bind(tokenHash, clientId, resource, now)
  #|       .first();
  #|     if (!row) return undefined;
  #|     return JSON.stringify({
  #|       token_hash: row.token_hash,
  #|       family_hash: row.family_hash,
  #|       client_id: row.client_id,
  #|       resource: row.resource,
  #|       scope: row.scope,
  #|       created_at: row.created_at,
  #|       expires_at: row.expires_at,
  #|     });
  #|   } catch (_) {
  #|     return "err";
  #|   }
  #| }

///|
struct RefreshTokenRow {
  token_hash : String
  family_hash : String
  client_id : String
  resource : String
  scope : String
  created_at : Int
  expires_at : Int
} derive(FromJson)

///|
pub async fn lookup_refresh_token(
  db : @cloudflare.D1Database,
  token_hash : String,
  client_id : String,
  resource : String,
  now : Int,
) -> RefreshTokenRecord? raise OAuthStorageError {
  let raw = lookup_refresh_token_js(
    db.as_any(),
    token_hash,
    client_id,
    resource,
    now,
  ).wait() catch {
    _ => raise OAuthStorageError("d1_lookup_failed")
  }
  match raw {
    Some("err") => raise OAuthStorageError("d1_lookup_failed")
    Some(value) => {
      let json = @json.parse(value) catch {
        _ => raise OAuthStorageError("d1_lookup_failed")
      }
      let row : RefreshTokenRow = @json.from_json(json) catch {
        _ => raise OAuthStorageError("d1_lookup_failed")
      }
      refresh_token_record(
        row.token_hash,
        row.family_hash,
        row.client_id,
        row.resource,
        row.scope,
        row.created_at,
        row.expires_at,
      )
    }
    None => None
  }
}

///|
/// Check the consumed_at marker of an exact-bound refresh-token row through
/// native D1. Returns 1 when visibly consumed, 0 when absent or unconsumed,
/// and -1 on a storage failure.
extern "js" fn refresh_token_consumed_js(
  db : @core.Any,
  token_hash : String,
  client_id : String,
  resource : String,
) -> @core.Promise[Int] =
  #| async (db, tokenHash, clientId, resource) => {
  #|   try {
  #|     const row = await db
  #|       .prepare("SELECT consumed_at FROM oauth_refresh_tokens WHERE token_hash = ? AND client_id = ? AND resource = ?")
  #|       .bind(tokenHash, clientId, resource)
  #|       .first();
  #|     if (!row) return 0;
  #|     return row.consumed_at === null || row.consumed_at === undefined ? 0 : 1;
  #|   } catch (_) {
  #|     return -1;
  #|   }
  #| }

///|
/// Classify an otherwise unusable refresh token as replay only when the exact
/// bound row is visibly consumed. This helper never mutates token state.
pub async fn refresh_token_replay_detected(
  db : @cloudflare.D1Database,
  token_hash : String,
  client_id : String,
  resource : String,
) -> Bool raise OAuthStorageError {
  let result = refresh_token_consumed_js(
    db.as_any(),
    token_hash,
    client_id,
    resource,
  ).wait() catch {
    _ => raise OAuthStorageError("d1_lookup_failed")
  }
  if result < 0 {
    raise OAuthStorageError("d1_lookup_failed")
  }
  result == 1
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
/// Rotate a refresh token and persist its replacement access token in the same
/// D1 batch, through the native D1 object for the Worker runtime. Returns 1
/// (rotated), 2 (replay), 0 (invalid), or -1 (storage error).
extern "js" fn rotate_refresh_token_with_access_js(
  db : @core.Any,
  old_token_hash : String,
  client_id : String,
  resource : String,
  replacement_token_hash : String,
  replacement_created_at : Int,
  replacement_expires_at : Int,
  now : Int,
  access_token_hash : String,
  access_created_at : Int,
  access_expires_at : Int,
) -> @core.Promise[Int] =
  #| async (db, oldTokenHash, clientId, resource, replacementTokenHash, replacementCreatedAt, replacementExpiresAt, now, accessTokenHash, accessCreatedAt, accessExpiresAt) => {
  #|   try {
  #|     const update = db
  #|       .prepare("UPDATE oauth_refresh_tokens SET consumed_at = ?, replacement_token_hash = ? WHERE token_hash = ? AND client_id = ? AND resource = ? AND expires_at > ? AND consumed_at IS NULL AND revoked_at IS NULL")
  #|       .bind(now, replacementTokenHash, oldTokenHash, clientId, resource, now);
  #|     const insertRefresh = db
  #|       .prepare("INSERT INTO oauth_refresh_tokens (token_hash, family_hash, client_id, resource, scope, created_at, expires_at) SELECT ?, family_hash, client_id, resource, scope, ?, ? FROM oauth_refresh_tokens WHERE token_hash = ? AND client_id = ? AND resource = ? AND consumed_at = ? AND replacement_token_hash = ?")
  #|       .bind(replacementTokenHash, replacementCreatedAt, replacementExpiresAt, oldTokenHash, clientId, resource, now, replacementTokenHash);
  #|     const insertAccess = db
  #|       .prepare("INSERT INTO oauth_access_tokens (token_hash, client_id, resource, scope, created_at, expires_at) SELECT ?, client_id, resource, scope, ?, ? FROM oauth_refresh_tokens WHERE token_hash = ? AND client_id = ? AND resource = ? AND consumed_at = ? AND replacement_token_hash = ?")
  #|       .bind(accessTokenHash, accessCreatedAt, accessExpiresAt, oldTokenHash, clientId, resource, now, replacementTokenHash);
  #|     const results = await db.batch([update, insertRefresh, insertAccess]);
  #|     if (!results || results.length !== 3) return -1;
  #|     const ok = results.every((r) => r && r.success !== false && r.meta?.changes === 1);
  #|     if (ok) return 1;
  #|     const row = await db
  #|       .prepare("SELECT consumed_at FROM oauth_refresh_tokens WHERE token_hash = ? AND client_id = ? AND resource = ?")
  #|       .bind(oldTokenHash, clientId, resource)
  #|       .first();
  #|     if (row && row.consumed_at !== null && row.consumed_at !== undefined) return 2;
  #|     return 0;
  #|   } catch (_) {
  #|     return -1;
  #|   }
  #| }

///|
/// Rotate a refresh token and persist its replacement access token in the same
/// D1 batch. No replacement secret is returned unless all durable writes commit.
pub async fn rotate_refresh_token_with_access(
  db : @cloudflare.D1Database,
  old_token_hash : String,
  client_id : String,
  resource : String,
  replacement_token_hash : String,
  replacement_created_at : Int,
  replacement_expires_at : Int,
  now : Int,
  access : AccessTokenRecord,
) -> RefreshRotationDecision raise OAuthStorageError {
  let result = rotate_refresh_token_with_access_js(
    db.as_any(),
    old_token_hash,
    client_id,
    resource,
    replacement_token_hash,
    replacement_created_at,
    replacement_expires_at,
    now,
    access.token_hash,
    access.created_at,
    access.expires_at,
  ).wait() catch {
    _ => raise OAuthStorageError("d1_rotate_failed")
  }
  match result {
    1 => RefreshRotated
    2 => RefreshReplay
    -1 => raise OAuthStorageError("d1_rotate_failed")
    _ => RefreshInvalid
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
/// Revoke the whole refresh-token family through native D1 for the Worker
/// runtime. Returns false on a storage failure.
extern "js" fn revoke_refresh_family_for_token_js(
  db : @core.Any,
  token_hash : String,
  client_id : String,
  resource : String,
  now : Int,
) -> @core.Promise[Bool] =
  #| async (db, tokenHash, clientId, resource, now) => {
  #|   try {
  #|     const result = await db
  #|       .prepare("UPDATE oauth_refresh_tokens SET revoked_at = ? WHERE family_hash = (SELECT family_hash FROM oauth_refresh_tokens WHERE token_hash = ? AND client_id = ? AND resource = ?) AND revoked_at IS NULL")
  #|       .bind(now, tokenHash, clientId, resource)
  #|       .run();
  #|     return Boolean(result && result.success !== false);
  #|   } catch (_) {
  #|     return false;
  #|   }
  #| }

///|
/// Revoke the full refresh-token family after replay detection without
/// exposing the family identifier to the endpoint layer.
pub async fn revoke_refresh_family_for_token(
  db : @cloudflare.D1Database,
  token_hash : String,
  client_id : String,
  resource : String,
  now : Int,
) -> Unit raise OAuthStorageError {
  let ok = revoke_refresh_family_for_token_js(
    db.as_any(),
    token_hash,
    client_id,
    resource,
    now,
  ).wait() catch {
    _ => raise OAuthStorageError("d1_revoke_failed")
  }
  if !ok {
    raise OAuthStorageError("d1_revoke_failed")
  }
}

///|
/// A dynamically registered OAuth client (RFC 7591). `redirect_uris` is
/// persisted as a JSON array string; `client_secret_hash` is a SHA-256 hex
/// digest and never the presented secret itself.
pub struct OAuthClientRecord {
  client_id : String
  client_name : String
  redirect_uris : Array[String]
  client_secret_hash : String?
  scope : String
  created_at : Int
}

///|
/// The subset of a registered client row the protocol layer needs.
/// `redirect_uris` stays the raw JSON array; parsing happens in MoonBit.
pub(all) struct StoredOAuthClient {
  client_name : String
  redirect_uris : String
  client_secret_hash : String?
  scope : String
}

///|
struct OAuthClientRow {
  client_name : String
  redirect_uris : String
  client_secret_hash : String?
  scope : String
} derive(FromJson)

///|
extern "js" fn insert_oauth_client_js(
  db : @core.Any,
  client_id : String,
  client_name : String,
  redirect_uris_json : String,
  has_secret : Bool,
  client_secret_hash : String,
  scope : String,
  created_at : Int,
) -> @core.Promise[Bool] =
  #| async (db, clientId, clientName, redirectUrisJson, hasSecret, clientSecretHash, scope, createdAt) => {
  #|   try {
  #|     const result = await db
  #|       .prepare("INSERT INTO oauth_clients (client_id, client_name, redirect_uris, client_secret_hash, scope, created_at) VALUES (?, ?, ?, ?, ?, ?)")
  #|       .bind(clientId, clientName, redirectUrisJson, hasSecret ? clientSecretHash : null, scope, createdAt)
  #|       .run();
  #|     return Boolean(result && result.success !== false);
  #|   } catch (_) {
  #|     return false;
  #|   }
  #| }

///|
pub async fn insert_oauth_client(
  db : @cloudflare.D1Database,
  record : OAuthClientRecord,
) -> Bool {
  let redirect_uris_json = ToJson::to_json(record.redirect_uris).stringify()
  insert_oauth_client_js(
    db.as_any(),
    record.client_id,
    record.client_name,
    redirect_uris_json,
    record.client_secret_hash is Some(_),
    record.client_secret_hash.unwrap_or(""),
    record.scope,
    record.created_at,
  ).wait() catch {
    _ => false
  }
}

///|
extern "js" fn get_oauth_client_js(
  db : @core.Any,
  client_id : String,
) -> @core.Promise[String?] =
  #| async (db, clientId) => {
  #|   try {
  #|     const row = await db
  #|       .prepare("SELECT client_name, redirect_uris, client_secret_hash, scope FROM oauth_clients WHERE client_id = ? AND revoked_at IS NULL")
  #|       .bind(clientId)
  #|       .first();
  #|     if (!row) return undefined;
  #|     return JSON.stringify({
  #|       client_name: row.client_name,
  #|       redirect_uris: row.redirect_uris,
  #|       client_secret_hash: row.client_secret_hash ?? null,
  #|       scope: row.scope,
  #|     });
  #|   } catch (_) {
  #|     return undefined;
  #|   }
  #| }

///|
/// Look up a live registered client. Missing and revoked registrations are
/// indistinguishable: both simply do not resolve to a client.
pub async fn get_oauth_client(
  db : @cloudflare.D1Database,
  client_id : String,
) -> StoredOAuthClient? {
  if client_id.is_empty() {
    return None
  }
  let raw = get_oauth_client_js(db.as_any(), client_id).wait() catch {
    _ => None
  }
  match raw {
    None => None
    Some(value) => {
      let json = @json.parse(value) catch { _ => return None }
      let row : OAuthClientRow = @json.from_json(json) catch {
        _ => return None
      }
      Some(StoredOAuthClient::{
        client_name: row.client_name,
        redirect_uris: row.redirect_uris,
        client_secret_hash: row.client_secret_hash,
        scope: row.scope,
      })
    }
  }
}

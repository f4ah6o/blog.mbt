///|
/// The result deliberately distinguishes an unusable credential from a valid
/// credential that does not authorize the requested operation.
pub(all) enum ProtectedResourceAuthorization {
  Authorized(AccessTokenRecord)
  MissingToken
  InvalidToken
  InsufficientScope
  InvalidConfiguration
  ServerError
} derive(Debug, Eq)

///|
pub fn protected_resource_decision(
  token : AccessTokenRecord?,
  required_scope : String,
) -> ProtectedResourceAuthorization {
  if !validate_protected_resource_scope(required_scope) {
    return InvalidConfiguration
  }
  match token {
    Some(value) =>
      if scope_contains(value.scope(), required_scope) {
        Authorized(value)
      } else {
        InsufficientScope
      }
    None => InvalidToken
  }
}

///|
/// Defense-in-depth validation for a token record already loaded from
/// persistence. The repository query also binds resource/expiry, but keeping
/// these checks in MoonBit makes the protected-resource contract explicit and
/// directly testable.
pub fn protected_resource_record_decision(
  token : AccessTokenRecord?,
  expected_resource : String,
  required_scope : String,
  now : Int,
) -> ProtectedResourceAuthorization {
  if !validate_protected_resource_scope(required_scope) ||
    expected_resource.is_empty() {
    return InvalidConfiguration
  }
  match token {
    Some(value) => {
      if value.resource() != expected_resource || value.expires_at() <= now {
        return InvalidToken
      }
      if scope_contains(value.scope(), required_scope) {
        Authorized(value)
      } else {
        InsufficientScope
      }
    }
    None => InvalidToken
  }
}

///|
/// Authorize one protected-resource request. The caller supplies only the
/// Authorization header value; query strings are intentionally not accepted.
pub async fn authorize_protected_resource(
  db : @cloudflare.D1Database,
  site_url : String,
  authorization_header : String?,
  required_scope : String,
  now : Int,
) -> ProtectedResourceAuthorization raise @cloudflare.D1Error {
  if !validate_protected_resource_scope(required_scope) {
    return InvalidConfiguration
  }
  let base = match canonical_base_url(site_url) {
    Some(value) => value
    None => return InvalidConfiguration
  }
  let resource = base + "/mcp"
  let header = match authorization_header {
    Some(value) => value
    None => return MissingToken
  }
  let bearer = match parse_bearer_header(header) {
    Some(value) => value
    None => return InvalidToken
  }
  let token_hash = sha256_hex(bearer.token) catch { _ => return ServerError }
  let token = lookup_access_token_for_resource(db, token_hash, resource, now)
  protected_resource_record_decision(token, resource, required_scope, now)
}

///|
/// Construct the RFC 6750/RFC 9728 challenge for this protected resource.
/// The required scope is always included when valid and is never inferred
/// from the token or accepted from the request.
pub fn protected_resource_challenge(
  site_url : String,
  required_scope : String,
  error : String?,
) -> String? {
  if !validate_protected_resource_scope(required_scope) {
    return None
  }
  let base = match canonical_base_url(site_url) {
    Some(value) => value
    None => return None
  }
  let metadata = base + "/.well-known/oauth-protected-resource"
  let mut challenge = "Bearer resource_metadata=\"" +
    metadata +
    "\", scope=\"" +
    required_scope +
    "\""
  match error {
    Some(value) if value == "invalid_token" || value == "insufficient_scope" =>
      challenge = "Bearer error=\"" +
        value +
        "\", resource_metadata=\"" +
        metadata +
        "\", scope=\"" +
        required_scope +
        "\""
    Some(_) => return None
    None => ()
  }
  Some(challenge)
}

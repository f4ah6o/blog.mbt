///|
pub const SCOPE_READ : String = "blog:read"

///|
pub const SCOPE_WRITE : String = "blog:write"

///|
pub const SCOPE_PUBLISH : String = "blog:publish"

///|
pub const SCOPE_OFFLINE_ACCESS : String = "offline_access"

///|
pub fn supported_scopes() -> Array[String] {
  [SCOPE_READ, SCOPE_WRITE, SCOPE_PUBLISH, SCOPE_OFFLINE_ACCESS]
}

///|
fn supported_scope(scope : String) -> Bool {
  scope == SCOPE_READ ||
  scope == SCOPE_WRITE ||
  scope == SCOPE_PUBLISH ||
  scope == SCOPE_OFFLINE_ACCESS
}

///|
/// Validate an OAuth scope parameter. OAuth scopes are space-delimited and
/// unknown, empty, or duplicated values are rejected rather than ignored.
pub fn validate_scope(scope : String) -> Bool {
  let trimmed = scope.trim().to_owned()
  if trimmed != scope || scope.is_empty() {
    return false
  }
  let seen : Array[String] = []
  for value in scope.split(" ") {
    let item = value.to_owned()
    if item.is_empty() || !supported_scope(item) || seen.contains(item) {
      return false
    }
    seen.push(item)
  }
  true
}

///|
pub fn scope_contains(granted : String, required : String) -> Bool {
  validate_scope(granted) && validate_scope(required) &&
    for_all_scope(required, fn(scope) {
      for item in granted.split(" ") {
        if item.to_owned() == scope {
          return true
        }
      }
      false
    })
}

///|
fn for_all_scope(value : String, predicate : (String) -> Bool) -> Bool {
  for item in value.split(" ") {
    if !predicate(item.to_owned()) {
      return false
    }
  }
  true
}

///|
/// Remove only trailing slashes from the configured origin/path. Callers must
/// provide a configured absolute HTTPS URL, not an arbitrary Host header.
pub fn canonical_base_url(value : String) -> String? {
  let trimmed = value.trim().to_owned()
  if trimmed.is_empty() || !trimmed.has_prefix("https://") {
    return None
  }
  let mut end = trimmed.length()
  while end > 0 && trimmed[end - 1] == '/' {
    end = end - 1
  }
  if end == 0 {
    None
  } else {
    Some(trimmed[:end].to_owned())
  }
}

///|
pub fn protected_resource_metadata(base_url : String) -> String {
  let base = match canonical_base_url(base_url) {
    Some(value) => value
    None => return "{}"
  }
  let metadata = ProtectedResourceMetadata::{
    resource: base + "/mcp",
    authorization_servers: [base],
    scopes_supported: supported_scopes(),
    bearer_methods_supported: ["header"],
  }
  ToJson::to_json(metadata).stringify()
}

///|
pub fn authorization_server_metadata(base_url : String) -> String {
  let base = match canonical_base_url(base_url) {
    Some(value) => value
    None => return "{}"
  }
  let metadata = AuthorizationServerMetadata::{
    issuer: base,
    authorization_endpoint: base + "/oauth/authorize",
    token_endpoint: base + "/oauth/token",
    response_types_supported: ["code"],
    grant_types_supported: ["authorization_code", "refresh_token"],
    code_challenge_methods_supported: ["S256"],
    scopes_supported: supported_scopes(),
    client_id_metadata_document_supported: true,
  }
  ToJson::to_json(metadata).stringify()
}

///|
struct ProtectedResourceMetadata {
  resource : String
  authorization_servers : Array[String]
  scopes_supported : Array[String]
  bearer_methods_supported : Array[String]
} derive(ToJson)

///|
struct AuthorizationServerMetadata {
  issuer : String
  authorization_endpoint : String
  token_endpoint : String
  response_types_supported : Array[String]
  grant_types_supported : Array[String]
  code_challenge_methods_supported : Array[String]
  scopes_supported : Array[String]
  client_id_metadata_document_supported : Bool
} derive(ToJson)

///|
fn valid_unreserved(value : String) -> Bool {
  if value.length() < 43 || value.length() > 128 {
    return false
  }
  for ch in value {
    let allowed =
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= 'a' && ch <= 'z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '-' || ch == '.' || ch == '_' || ch == '~'
    if !allowed {
      return false
    }
  }
  true
}

///|
pub fn validate_pkce_verifier(verifier : String) -> Bool {
  valid_unreserved(verifier)
}

///|
pub fn validate_pkce_challenge(challenge : String) -> Bool {
  if challenge.length() != 43 {
    return false
  }
  for ch in challenge {
    let allowed =
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= 'a' && ch <= 'z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '-' || ch == '_'
    if !allowed {
      return false
    }
  }
  true
}

///|
/// Calculate the RFC 7636 S256 challenge. WebCrypto is deliberately limited
/// to the digest capability; verifier syntax stays in MoonBit.
pub async fn pkce_s256(verifier : String) -> String? {
  if !validate_pkce_verifier(verifier) {
    return None
  }
  Some(pkce_s256_js(verifier).wait())
}

///|
extern "js" fn pkce_s256_js(verifier : String) -> @core.Promise[String] =
  #| async (verifier) => {
  #|   const bytes = new TextEncoder().encode(verifier);
  #|   const digest = await crypto.subtle.digest("SHA-256", bytes);
  #|   const raw = String.fromCharCode(...new Uint8Array(digest));
  #|   return btoa(raw).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  #| }

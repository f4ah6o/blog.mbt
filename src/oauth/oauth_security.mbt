///|
/// An opaque bearer secret. The syntax is deliberately restricted to the
/// unpadded base64url output produced by generate_opaque_secret.
pub fn validate_opaque_secret(value : String) -> Bool {
  if value.length() < 43 || value.length() > 128 {
    return false
  }
  for ch in value {
    let allowed = (ch >= 'A' && ch <= 'Z') ||
      (ch >= 'a' && ch <= 'z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '-' ||
      ch == '_'
    if !allowed {
      return false
    }
  }
  true
}

///|
/// Generate 256 bits of opaque randomness. WebCrypto is used only as the
/// runtime CSPRNG capability; encoding and validation stay in this package.
pub async fn generate_opaque_secret() -> String {
  generate_opaque_secret_js().wait()
}

///|
extern "js" fn generate_opaque_secret_js() -> @core.Promise[String] =
  #| async () => {
  #|   const bytes = new Uint8Array(32);
  #|   crypto.getRandomValues(bytes);
  #|   const raw = String.fromCharCode(...bytes);
  #|   return btoa(raw).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  #| }

///|
/// Return the lowercase hexadecimal SHA-256 digest for persistence and
/// lookup. The input is never logged or returned by the FFI.
pub async fn sha256_hex(value : String) -> String {
  sha256_hex_js(value).wait()
}

///|
pub fn validate_sha256_hex(value : String) -> Bool {
  if value.length() != 64 {
    return false
  }
  for ch in value {
    let valid = (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f')
    if !valid {
      return false
    }
  }
  true
}

///|
extern "js" fn sha256_hex_js(value : String) -> @core.Promise[String] =
  #| async (value) => {
  #|   const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  #|   return Array.from(new Uint8Array(digest), byte => byte.toString(16).padStart(2, "0")).join("");
  #| }

///|
pub struct BearerToken {
  token : String
} derive(Debug, Eq)

///|
/// Parse one Authorization header. Multiple values, empty values, delimiters,
/// and non-canonical opaque secrets fail closed without exposing the secret.
pub fn parse_bearer_header(value : String) -> BearerToken? {
  if value.length() < 8 || value.contains(","[:]) {
    return None
  }
  if value[:6].to_owned().to_upper() != "BEARER" || value[6] != ' ' {
    return None
  }
  let mut token_start = 7
  while token_start < value.length() && value[token_start] == ' ' {
    token_start = token_start + 1
  }
  if token_start >= value.length() {
    return None
  }
  let token = value[token_start:].to_owned()
  if validate_opaque_secret(token) {
    Some(BearerToken::{ token, })
  } else {
    None
  }
}

///|
/// Verify the S256 challenge bound to an authorization code. Invalid verifier
/// or challenge syntax fails closed before comparison.
pub async fn verify_pkce_s256(
  code_challenge : String,
  code_verifier : String,
) -> Bool {
  if !validate_pkce_challenge(code_challenge) ||
    !validate_pkce_verifier(code_verifier) {
    return false
  }
  match pkce_s256(code_verifier) {
    Some(calculated) => calculated == code_challenge
    None => false
  }
}

///|
pub fn is_unexpired(expires_at : Int, now : Int) -> Bool {
  expires_at > now
}

///|
pub fn redeem_is_allowed(
  matches : Bool,
  consumed_at : Int?,
  expires_at : Int,
  now : Int,
) -> Bool {
  matches && consumed_at is None && is_unexpired(expires_at, now)
}

///|
pub(all) enum RefreshRotationDecision {
  RefreshRotated
  RefreshReplay
  RefreshInvalid
} derive(Debug, Eq)

///|
pub fn refresh_rotation_decision(
  matches : Bool,
  consumed_at : Int?,
  revoked_at : Int?,
  expires_at : Int,
  now : Int,
) -> RefreshRotationDecision {
  if !matches || revoked_at is Some(_) || !is_unexpired(expires_at, now) {
    RefreshInvalid
  } else if consumed_at is Some(_) {
    RefreshReplay
  } else {
    RefreshRotated
  }
}

///|
/// A structurally validated Client ID Metadata Document (CIMD). The
/// representation is private: callers obtain one only from
/// `parse_client_metadata` and can only ask whether a redirect URI is declared.
pub struct ClientMetadata {
  client_id : String
  client_name : String
  redirect_uris : Array[String]
}

///|
/// The subset of the CIMD document this slice needs. Unknown metadata fields
/// are ignored by the derived decoder; the document identifier is mandatory.
struct ClientMetadataDocument {
  client_id : String
  client_name : String
  redirect_uris : Array[String]?
} derive(FromJson)

///|
/// Only absolute HTTPS client identifiers without a fragment or whitespace are
/// eligible to be fetched. The identifier is the metadata document URL.
pub fn validate_client_id_url(value : String) -> Bool {
  if !value.has_prefix("https://") ||
    value.contains("#"[:]) ||
    value.contains("?"[:]) {
    return false
  }
  for ch in value {
    if ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n' {
      return false
    }
  }
  let rest = value["https://".length():].to_owned()
  let mut first = true
  let mut has_path = false
  for part in rest.split("/") {
    let segment = part.to_owned()
    if first {
      if segment.is_empty() || segment.contains("@"[:]) {
        return false
      }
      first = false
    } else {
      has_path = true
      if segment == "." || segment == ".." {
        return false
      }
    }
  }
  has_path
}

///|
/// Parse a fetched CIMD document and bind it to the requested client_id. The
/// document MUST declare a `client_id` exactly equal to the requested URL and
/// at least one declared redirect URI; every declared redirect URI MUST be an
/// absolute HTTPS URI without a fragment. A missing identifier, a mismatch, a
/// non-HTTPS URI, or malformed JSON fails closed.
pub fn parse_client_metadata(
  requested_client_id : String,
  raw_metadata : String,
) -> ClientMetadata? {
  if !validate_client_id_url(requested_client_id) {
    return None
  }
  let json = @json.parse(raw_metadata) catch { _ => return None }
  let document : ClientMetadataDocument = @json.from_json(json) catch {
    _ => return None
  }
  if document.client_id != requested_client_id {
    return None
  }
  if document.client_name.trim().to_owned().is_empty() {
    return None
  }
  let redirect_uris = match document.redirect_uris {
    Some(values) if values.length() > 0 => values
    _ => return None
  }
  for uri in redirect_uris {
    if !valid_redirect_uri(uri) {
      return None
    }
  }
  Some(ClientMetadata::{
    client_id: requested_client_id,
    client_name: document.client_name,
    redirect_uris,
  })
}

///|
/// Whether the declared CIMD document permits this redirect target. The check
/// is byte-for-byte; no normalization is performed.
pub fn ClientMetadata::redirect_uri_allowed(
  self : ClientMetadata,
  redirect_uri : String,
) -> Bool {
  self.redirect_uris.contains(redirect_uri)
}

///|
/// The server-validated authorization request. The representation is private so
/// later protocol steps cannot treat client-supplied values as authoritative.
pub struct AuthorizationRequest {
  client_id : String
  redirect_uri : String
  resource : String
  scope : String
  code_challenge : String
  code_challenge_method : String
  state : String?
} derive(ToJson, FromJson)

///|
/// Serialize a validated request for short-lived server-side pending storage.
pub fn AuthorizationRequest::to_json_string(
  self : AuthorizationRequest,
) -> String {
  ToJson::to_json(self).stringify()
}

///|
pub fn AuthorizationRequest::from_json_string(
  raw : String,
) -> AuthorizationRequest? {
  let json = @json.parse(raw) catch { _ => return None }
  let request : AuthorizationRequest = @json.from_json(json) catch {
    _ => return None
  }
  Some(request)
}

///|
/// Derive the authorization-code row only from the server-validated request,
/// never from a later client submission.
pub fn AuthorizationRequest::code_record(
  self : AuthorizationRequest,
  code_hash : String,
  created_at : Int,
  expires_at : Int,
) -> AuthorizationCodeRecord? {
  authorization_code_record(
    code_hash,
    self.client_id,
    self.redirect_uri,
    self.resource,
    self.scope,
    self.code_challenge,
    self.code_challenge_method,
    created_at,
    expires_at,
  )
}

///|
/// Build the final redirect from the stored request so `state` and the exact
/// declared `redirect_uri` cannot be swapped by the client at verify time.
pub fn AuthorizationRequest::code_redirect(
  self : AuthorizationRequest,
  code : String,
) -> String {
  authorization_redirect(self.redirect_uri, "code", code, self.state)
}

///|
/// Construct a successful authorization redirect with the RFC 9207 issuer.
pub fn AuthorizationRequest::code_redirect_with_issuer(
  self : AuthorizationRequest,
  code : String,
  issuer : String,
) -> String {
  authorization_redirect_with_issuer(
    self.redirect_uri,
    "code",
    code,
    self.state,
    issuer,
  )
}

///|
/// Validate every authorization request binding against a previously parsed
/// CIMD document. Redirect URI comparison is deliberately byte-for-byte.
pub fn validate_authorization_request(
  response_type : String,
  client_id : String,
  redirect_uri : String,
  resource : String,
  scope : String,
  code_challenge : String,
  code_challenge_method : String,
  state : String?,
  expected_resource : String,
  client : ClientMetadata,
) -> AuthorizationRequest? {
  if response_type != "code" ||
    client_id.is_empty() ||
    client.client_id != client_id ||
    redirect_uri.is_empty() ||
    !client.redirect_uri_allowed(redirect_uri) ||
    !valid_redirect_uri(redirect_uri) ||
    resource != expected_resource ||
    !validate_scope(scope) ||
    !validate_pkce_challenge(code_challenge) ||
    code_challenge_method != "S256" {
    return None
  }
  Some(AuthorizationRequest::{
    client_id,
    redirect_uri,
    resource,
    scope,
    code_challenge,
    code_challenge_method,
    state,
  })
}

///|
/// Only absolute HTTPS redirect URIs without fragments are accepted. The
/// declared CIMD URI is still compared exactly by validate_authorization_request.
pub fn valid_redirect_uri(value : String) -> Bool {
  if !value.has_prefix("https://") || value.contains("#"[:]) {
    return false
  }
  for ch in value {
    if ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n' {
      return false
    }
  }
  value.length() > "https://".length()
}

///|
/// Construct an OAuth redirect without allowing state or error text to become
/// query syntax. URL encoding is delegated to the platform URL implementation.
pub fn authorization_redirect(
  redirect_uri : String,
  parameter : String,
  value : String,
  state : String?,
) -> String {
  match state {
    Some(value_state) =>
      authorization_redirect_with_state_js(
        redirect_uri, parameter, value, value_state,
      )
    None => authorization_redirect_js(redirect_uri, parameter, value)
  }
}

///|
/// Add the RFC 9207 issuer to a successful authorization response.
pub fn authorization_redirect_with_issuer(
  redirect_uri : String,
  parameter : String,
  value : String,
  state : String?,
  issuer : String,
) -> String {
  match state {
    Some(value_state) =>
      authorization_redirect_with_issuer_and_state_js(
        redirect_uri, parameter, value, value_state, issuer,
      )
    None =>
      authorization_redirect_with_issuer_js(
        redirect_uri, parameter, value, issuer,
      )
  }
}

///|
extern "js" fn authorization_redirect_js(
  redirect_uri : String,
  parameter : String,
  value : String,
) -> String =
  #| (redirectUri, parameter, value) => {
  #|   const url = new URL(redirectUri);
  #|   url.searchParams.set(parameter, value);
  #|   return url.toString();
  #| }

///|
extern "js" fn authorization_redirect_with_state_js(
  redirect_uri : String,
  parameter : String,
  value : String,
  state : String,
) -> String =
  #| (redirectUri, parameter, value, state) => {
  #|   const url = new URL(redirectUri);
  #|   url.searchParams.set(parameter, value);
  #|   url.searchParams.set("state", state);
  #|   return url.toString();
  #| }

///|
extern "js" fn authorization_redirect_with_issuer_js(
  redirect_uri : String,
  parameter : String,
  value : String,
  issuer : String,
) -> String =
  #| (redirectUri, parameter, value, issuer) => {
  #|   const url = new URL(redirectUri);
  #|   url.searchParams.set(parameter, value);
  #|   url.searchParams.set("iss", issuer);
  #|   return url.toString();
  #| }

///|
extern "js" fn authorization_redirect_with_issuer_and_state_js(
  redirect_uri : String,
  parameter : String,
  value : String,
  state : String,
  issuer : String,
) -> String =
  #| (redirectUri, parameter, value, state, issuer) => {
  #|   const url = new URL(redirectUri);
  #|   url.searchParams.set(parameter, value);
  #|   url.searchParams.set("state", state);
  #|   url.searchParams.set("iss", issuer);
  #|   return url.toString();
  #| }

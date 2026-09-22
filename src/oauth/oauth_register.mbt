///|
/// RFC 7591 dynamic client registration. The endpoint accepts a bounded
/// subset of client metadata; everything else is ignored or rejected.

///|
/// The maximum redirect URIs one registration may declare.
const MAX_REGISTERED_REDIRECT_URIS : Int = 10

///|
/// The maximum accepted registration body length in characters.
pub const MAX_REGISTRATION_BODY_LENGTH : Int = 65536

///|
/// Client metadata accepted by POST /oauth/register after validation.
pub struct ClientRegistration {
  client_name : String
  redirect_uris : Array[String]
  token_endpoint_auth_method : String
  grant_types : Array[String]
  scope : String
}

///|
/// The raw request body shape. Unknown fields are ignored by the decoder.
struct ClientRegistrationRequest {
  client_name : String?
  redirect_uris : Array[String]?
  token_endpoint_auth_method : String?
  grant_types : Array[String]?
  response_types : Array[String]?
  scope : String?
} derive(FromJson)

///|
/// Parse and validate an RFC 7591 registration request. Redirect URIs are
/// mandatory and every entry must be an absolute HTTPS URI without a
/// fragment. `token_endpoint_auth_method` accepts only "none",
/// "client_secret_post", and "client_secret_basic"; anything else fails.
/// Declared grant and response types may only name what this server issues.
pub fn parse_client_registration(body : String) -> ClientRegistration? {
  if body.is_empty() || body.length() > MAX_REGISTRATION_BODY_LENGTH {
    return None
  }
  let json = @json.parse(body) catch { _ => return None }
  let request : ClientRegistrationRequest = @json.from_json(json) catch {
    _ => return None
  }
  let redirect_uris = match request.redirect_uris {
    Some(values) if values.length() > 0 &&
      values.length() <= MAX_REGISTERED_REDIRECT_URIS => values
    _ => return None
  }
  for uri in redirect_uris {
    if !valid_redirect_uri(uri) {
      return None
    }
  }
  let client_name = match request.client_name {
    Some(name) => {
      let trimmed = name.trim().to_owned()
      if trimmed.is_empty() || trimmed.length() > 100 {
        return None
      }
      trimmed
    }
    None => ""
  }
  let token_endpoint_auth_method = match request.token_endpoint_auth_method {
    None => "none"
    Some("none") => "none"
    Some("client_secret_post") => "client_secret_post"
    Some("client_secret_basic") => "client_secret_basic"
    Some(_) => return None
  }
  let grant_types = match request.grant_types {
    None => ["authorization_code", "refresh_token"]
    Some(values) => {
      if values.is_empty() || !values.contains("authorization_code") {
        return None
      }
      for value in values {
        if value != "authorization_code" && value != "refresh_token" {
          return None
        }
      }
      values
    }
  }
  match request.response_types {
    None => ()
    Some(values) =>
      if !(values.length() == 1 && values[0] == "code") {
        return None
      }
  }
  let scope = match request.scope {
    None => ""
    Some(value) => if validate_scope(value) { value } else { return None }
  }
  Some(ClientRegistration::{
    client_name,
    redirect_uris,
    token_endpoint_auth_method,
    grant_types,
    scope,
  })
}

///|
/// Whether the registration requires an issued client secret at the token
/// endpoint. Public clients ("none") rely on PKCE alone.
pub fn ClientRegistration::requires_secret(self : ClientRegistration) -> Bool {
  self.token_endpoint_auth_method != "none"
}

///|
/// Persisted record for a new registration. `client_secret_hash` is present
/// only when the client registered as confidential.
pub fn ClientRegistration::record(
  self : ClientRegistration,
  client_id : String,
  client_secret_hash : String?,
  created_at : Int,
) -> OAuthClientRecord {
  let client_name = if self.client_name.is_empty() {
    client_id
  } else {
    self.client_name
  }
  OAuthClientRecord::{
    client_id,
    client_name,
    redirect_uris: self.redirect_uris,
    client_secret_hash,
    scope: self.scope,
    created_at,
  }
}

///|
/// The RFC 7591 client information response. `client_secret` is included
/// only at issuance time; `client_secret_expires_at: 0` marks a secret that
/// never expires.
pub fn ClientRegistration::response_json(
  self : ClientRegistration,
  client_id : String,
  client_secret : String?,
  issued_at : Int,
) -> String {
  let fields : Map[String, Json] = Map::Map([])
  fields["client_id"] = client_id.to_json()
  fields["client_id_issued_at"] = issued_at.to_json()
  match client_secret {
    Some(secret) => {
      fields["client_secret"] = secret.to_json()
      fields["client_secret_expires_at"] = Json::number(0)
    }
    None => ()
  }
  let client_name = if self.client_name.is_empty() {
    client_id
  } else {
    self.client_name
  }
  fields["client_name"] = client_name.to_json()
  fields["redirect_uris"] = self.redirect_uris.to_json()
  fields["grant_types"] = self.grant_types.to_json()
  fields["response_types"] = ["code"].to_json()
  fields["token_endpoint_auth_method"] = self.token_endpoint_auth_method.to_json()
  if !self.scope.is_empty() {
    fields["scope"] = self.scope.to_json()
  }
  Json::object(fields).stringify()
}

///|
/// Build client metadata for the authorize endpoint from a stored
/// registration. The stored JSON array is re-validated entry by entry so a
/// corrupted row fails closed.
pub fn stored_client_metadata(
  client_id : String,
  stored : StoredOAuthClient,
) -> ClientMetadata? {
  let json = @json.parse(stored.redirect_uris) catch { _ => return None }
  let redirect_uris : Array[String] = @json.from_json(json) catch {
    _ => return None
  }
  registered_client_metadata(client_id, stored.client_name, redirect_uris)
}

///|
/// Whether a presented secret satisfies a stored registration. Clients that
/// are not registered (CIMD) and public registrations have no secret to
/// verify and always pass.
pub async fn registered_client_secret_ok(
  stored : StoredOAuthClient?,
  presented : String,
) -> Bool {
  match stored {
    None => true
    Some(client) =>
      match client.client_secret_hash {
        None => true
        Some(hash) =>
          if presented.is_empty() || presented.length() > 512 {
            false
          } else {
            sha256_hex(presented) == hash
          }
      }
  }
}

///|
/// Conservative OAuth token lifetimes. Secrets are generated only after the
/// request has passed syntax validation and are persisted as hashes.
pub const ACCESS_TOKEN_TTL_SECONDS : Int = 3600

///|
pub const REFRESH_TOKEN_TTL_SECONDS : Int = 30 * 24 * 60 * 60

///|
struct FormPair {
  name : String
  value : String
} derive(FromJson)

///|
pub struct OAuthTokenRequest {
  grant_type : String
  code : String?
  client_id : String?
  redirect_uri : String?
  resource : String?
  code_verifier : String?
  refresh_token : String?
  client_secret : String?
}

///|
pub fn OAuthTokenRequest::grant_type(self : OAuthTokenRequest) -> String {
  self.grant_type
}

///|
pub fn OAuthTokenRequest::code(self : OAuthTokenRequest) -> String? {
  self.code
}

///|
pub fn OAuthTokenRequest::client_id(self : OAuthTokenRequest) -> String? {
  self.client_id
}

///|
pub fn OAuthTokenRequest::redirect_uri(self : OAuthTokenRequest) -> String? {
  self.redirect_uri
}

///|
pub fn OAuthTokenRequest::resource(self : OAuthTokenRequest) -> String? {
  self.resource
}

///|
pub fn OAuthTokenRequest::code_verifier(self : OAuthTokenRequest) -> String? {
  self.code_verifier
}

///|
pub fn OAuthTokenRequest::refresh_token(self : OAuthTokenRequest) -> String? {
  self.refresh_token
}

///|
pub fn OAuthTokenRequest::client_secret(self : OAuthTokenRequest) -> String? {
  self.client_secret
}

///|
pub(all) enum TokenGrant {
  AuthorizationCode
  RefreshToken
} derive(Debug, Eq)

///|
/// Parse exactly one occurrence of each form field. The runtime helper rejects
/// invalid percent escapes before decoding; MoonBit applies the allow-list and
/// retains presence separately from an empty value.
pub fn parse_oauth_token_form(body : String) -> OAuthTokenRequest? {
  let raw = parse_form_pairs_js(body)
  let json = @json.parse(raw) catch { _ => return None }
  let pairs : Array[FormPair] = @json.from_json(json) catch { _ => return None }
  let mut grant_type : String? = None
  let mut code : String? = None
  let mut client_id : String? = None
  let mut redirect_uri : String? = None
  let mut resource : String? = None
  let mut code_verifier : String? = None
  let mut refresh_token : String? = None
  let mut client_secret : String? = None
  for pair in pairs {
    match pair.name {
      "grant_type" =>
        if grant_type is Some(_) {
          return None
        } else {
          grant_type = Some(pair.value)
        }
      "code" =>
        if code is Some(_) {
          return None
        } else {
          code = Some(pair.value)
        }
      "client_id" =>
        if client_id is Some(_) {
          return None
        } else {
          client_id = Some(pair.value)
        }
      "redirect_uri" =>
        if redirect_uri is Some(_) {
          return None
        } else {
          redirect_uri = Some(pair.value)
        }
      "resource" =>
        if resource is Some(_) {
          return None
        } else {
          resource = Some(pair.value)
        }
      "code_verifier" =>
        if code_verifier is Some(_) {
          return None
        } else {
          code_verifier = Some(pair.value)
        }
      "refresh_token" =>
        if refresh_token is Some(_) {
          return None
        } else {
          refresh_token = Some(pair.value)
        }
      "client_secret" =>
        if client_secret is Some(_) {
          return None
        } else {
          client_secret = Some(pair.value)
        }
      _ => return None
    }
  }
  Some(OAuthTokenRequest::{
    grant_type: grant_type.unwrap_or(""),
    code,
    client_id,
    redirect_uri,
    resource,
    code_verifier,
    refresh_token,
    client_secret,
  })
}

///|
pub fn validate_oauth_token_request(request : OAuthTokenRequest) -> TokenGrant? {
  match request.grant_type {
    "authorization_code" =>
      if !present_valid(request.code) ||
        !present_valid(request.client_id) ||
        !present_valid(request.redirect_uri) ||
        !present_valid(request.code_verifier) ||
        request.refresh_token is Some(_) {
        None
      } else {
        match (request.code, request.code_verifier) {
          (Some(_), Some(verifier)) if validate_pkce_verifier(verifier) =>
            Some(AuthorizationCode)
          _ => None
        }
      }
    "refresh_token" =>
      if !present_valid(request.refresh_token) ||
        !present_valid(request.client_id) ||
        request.code is Some(_) ||
        request.redirect_uri is Some(_) ||
        request.code_verifier is Some(_) {
        None
      } else {
        match request.refresh_token {
          Some(_) => Some(RefreshToken)
          _ => None
        }
      }
    _ => None
  }
}

///|
fn present_valid(value : String?) -> Bool {
  match value {
    Some(value) => !value.is_empty()
    None => false
  }
}

///|
extern "js" fn parse_form_pairs_js(body : String) -> String =
  #| (body) => {
  #|   const pairs = [];
  #|   if (body.length === 0) return "[]";
  #|   for (const part of body.split("&")) {
  #|     const separator = part.indexOf("=");
  #|     const rawName = separator < 0 ? part : part.slice(0, separator);
  #|     const rawValue = separator < 0 ? "" : part.slice(separator + 1);
  #|     if (/%(?![0-9a-fA-F]{2})/.test(rawName) || /%(?![0-9a-fA-F]{2})/.test(rawValue)) return "null";
  #|     try {
  #|       pairs.push({
  #|         name: decodeURIComponent(rawName.replace(/\+/g, " ")),
  #|         value: decodeURIComponent(rawValue.replace(/\+/g, " ")),
  #|       });
  #|     } catch (_) { return "null"; }
  #|   }
  #|   return JSON.stringify(pairs);
  #| }

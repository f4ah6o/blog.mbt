///|
/// The verify endpoint accepts only the WebAuthn assertion. The OAuth request
/// is never read from this body; it is recovered from server-side pending
/// storage keyed by challenge_id.
struct OAuthVerifyRequest {
  challenge_id : String
  credential_id : String
  raw_id : String
  client_data_json : String
  authenticator_data : String
  signature : String
} derive(FromJson)

///|
fn oauth_expected_resource() -> String? {
  match @oauth.canonical_base_url(@config.SITE_URL) {
    Some(base) => Some(base + "/mcp")
    None => None
  }
}

///|
fn oauth_error_response(
  url : @core.Any,
  client : @oauth.ClientMetadata?,
  error : String,
) -> @http.Response {
  let redirect_uri = get_search_param(url, "redirect_uri")
  match (redirect_uri, client) {
    (Some(candidate), Some(metadata)) if metadata.redirect_uri_allowed(
        candidate,
      ) =>
      redirect_response(
        @oauth.authorization_redirect(
          candidate,
          "error",
          error,
          get_search_param(url, "state"),
        ),
      )
    _ => json_response("{\"error\":\"invalid_request\"}", 400)
  }
}

///|
/// The authorization page receives the server-generated WebAuthn options
/// directly. It never forwards the OAuth request to the verify endpoint.
fn authorization_page(options_json : String) -> String {
  "<!doctype html><html><head><meta charset=\"utf-8\"><title>Authorize</title></head><body>" +
  "<h1>Authorize access</h1><p>Use your passkey to continue.</p>" +
  "<button id=\"authorize\">Continue with passkey</button><p id=\"status\"></p>" +
  "<script>" +
  "const o=" +
  options_json +
  ";" +
  "const button=document.getElementById('authorize');const status=document.getElementById('status');" +
  "const b64=(s)=>{const p=s.replace(/-/g,'+').replace(/_/g,'/');const x=p+'='.repeat((4-p.length%4)%4);const b=atob(x);const a=new Uint8Array(b.length);for(let i=0;i<b.length;i++)a[i]=b.charCodeAt(i);return a.buffer};" +
  "const enc=(b)=>{const a=new Uint8Array(b);let s='';for(const x of a)s+=String.fromCharCode(x);return btoa(s).replace(/\\+/g,'-').replace(/\\//g,'_').replace(/=/g,'')};" +
  "button.onclick=async()=>{button.disabled=true;try{" +
  "const c=await navigator.credentials.get({publicKey:{challenge:b64(o.challenge),timeout:o.timeout,rpId:o.rp_id,userVerification:o.user_verification,allowCredentials:o.allow_credentials.map(x=>({id:b64(x.id),type:x.type,transports:x.transports||[]}))}});" +
  "const r=await fetch('/oauth/authorize/verify',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({challenge_id:o.challenge_id,credential_id:enc(c.rawId),raw_id:enc(c.rawId),client_data_json:enc(c.response.clientDataJSON),authenticator_data:enc(c.response.authenticatorData),signature:enc(c.response.signature)})});" +
  "if(!r.ok)throw new Error('Passkey verification failed');location.href=await r.text();" +
  "}catch(e){status.textContent=e.message;button.disabled=false}};" +
  "</script></body></html>"
}

///|
/// Validate the OAuth request from the query string, create the WebAuthn
/// challenge, and persist the server-side binding between them. The page then
/// talks only to the verify endpoint.
async fn handle_oauth_authorize(
  env : @cloudflare.CloudflareEnv,
  url : @core.Any,
) -> @http.Response {
  let expected_resource = match oauth_expected_resource() {
    Some(value) => value
    None => return json_response("{\"error\":\"server_configuration\"}", 500)
  }
  let client_id = get_search_param(url, "client_id").unwrap_or("")
  let raw_metadata = match @oauth.fetch_client_metadata_document(client_id) {
    Some(value) => value
    None => return json_response("{\"error\":\"invalid_client\"}", 400)
  }
  let client = match @oauth.parse_client_metadata(client_id, raw_metadata) {
    Some(value) => value
    None => return json_response("{\"error\":\"invalid_client\"}", 400)
  }
  let request = match
    @oauth.validate_authorization_request(
      get_search_param(url, "response_type").unwrap_or(""),
      client_id,
      get_search_param(url, "redirect_uri").unwrap_or(""),
      get_search_param(url, "resource").unwrap_or(""),
      get_search_param(url, "scope").unwrap_or(""),
      get_search_param(url, "code_challenge").unwrap_or(""),
      get_search_param(url, "code_challenge_method").unwrap_or(""),
      get_search_param(url, "state"),
      expected_resource,
      client,
    ) {
    Some(value) => value
    None => return oauth_error_response(url, Some(client), "invalid_request")
  }
  let kv = match @identity.get_oauth_auth_kv(env) {
    Some(value) => value
    None => return json_response("{\"error\":\"identity_unavailable\"}", 503)
  }
  let user_id = match @identity.get_oauth_user_id(env) {
    Some(value) => value
    None => return json_response("{\"error\":\"identity_unavailable\"}", 503)
  }
  let rp_id = match @identity.get_oauth_rp_id(env) {
    Some(value) => value
    None => return json_response("{\"error\":\"identity_unavailable\"}", 503)
  }
  let now = oauth_now()
  let options = @identity.generate_auth_options(kv, user_id, rp_id)
  let challenge_id = options.challenge_identifier()
  let pending = match
    @oauth.pending_authorization(
      challenge_id,
      user_id,
      request,
      now,
      @oauth.PENDING_AUTHORIZATION_TTL_SECONDS,
    ) {
    Some(value) => value
    None => {
      @identity.delete_challenge(kv, user_id, challenge_id)
      return json_response("{\"error\":\"server_error\"}", 500)
    }
  }
  let db_value = get_db_from_env(env)
  if @core.typeof_(db_value) == "undefined" || @core.is_null(db_value) {
    @identity.delete_challenge(kv, user_id, challenge_id)
    return json_response("{\"error\":\"storage_unavailable\"}", 503)
  }
  let db : @cloudflare.D1Database = @core.identity(db_value)
  @oauth.insert_pending_authorization(db, pending) catch {
    _ => {
      @identity.delete_challenge(kv, user_id, challenge_id)
      return json_response("{\"error\":\"server_error\"}", 500)
    }
  }
  html_response_js(authorization_page(options.to_json().stringify()), 200)
}

///|
async fn handle_oauth_verify(
  env : @cloudflare.CloudflareEnv,
  req : @cloudflare.CloudflareRequest,
) -> @http.Response {
  let http_req : @http.Request = @core.identity(req)
  let body = http_req.text()
  let json = @json.parse(body) catch {
    _ => return json_response("{\"error\":\"invalid_request\"}", 400)
  }
  let input : OAuthVerifyRequest = @json.from_json(json) catch {
    _ => return json_response("{\"error\":\"invalid_request\"}", 400)
  }
  let kv = match @identity.get_oauth_auth_kv(env) {
    Some(value) => value
    None => return json_response("{\"error\":\"identity_unavailable\"}", 503)
  }
  let user_id = match @identity.get_oauth_user_id(env) {
    Some(value) => value
    None => return json_response("{\"error\":\"identity_unavailable\"}", 503)
  }
  let rp_id = match @identity.get_oauth_rp_id(env) {
    Some(value) => value
    None => return json_response("{\"error\":\"identity_unavailable\"}", 503)
  }
  let origin = match @identity.get_oauth_origin(env) {
    Some(value) => value
    None => return json_response("{\"error\":\"identity_unavailable\"}", 503)
  }
  let issuer = match @oauth.canonical_base_url(@config.SITE_URL) {
    Some(value) => value
    None => return json_response("{\"error\":\"server_configuration\"}", 500)
  }
  if origin != issuer {
    return json_response("{\"error\":\"identity_unavailable\"}", 503)
  }
  let now = oauth_now()
  let verify_request = @identity.AuthVerifyRequest::new(
    input.challenge_id,
    input.credential_id,
    input.raw_id,
    input.client_data_json,
    input.authenticator_data,
    input.signature,
  )
  match
    @identity.verify_authentication(kv, user_id, rp_id, origin, verify_request) {
    @identity.AuthVerifyResult::Success(_) => ()
    _ =>
      return json_response("{\"error\":\"identity_verification_failed\"}", 401)
  }
  let db_value = get_db_from_env(env)
  if @core.typeof_(db_value) == "undefined" || @core.is_null(db_value) {
    return json_response("{\"error\":\"storage_unavailable\"}", 503)
  }
  let db : @cloudflare.D1Database = @core.identity(db_value)
  let request = match
    @oauth.claim_pending_authorization(db, input.challenge_id, user_id, now) {
    Some(value) => value
    None => return json_response("{\"error\":\"invalid_request\"}", 400)
  }
  let secret = @oauth.generate_opaque_secret()
  let hash = @oauth.sha256_hex(secret)
  let record = match request.code_record(hash, now, now + 60) {
    Some(value) => value
    None => return json_response("{\"error\":\"server_error\"}", 500)
  }
  @oauth.insert_authorization_code(db, record) catch {
    _ => return json_response("{\"error\":\"server_error\"}", 500)
  }
  text_response_js(request.code_redirect(secret), 200)
}

///|
pub async fn handle_oauth_request(
  req : @cloudflare.CloudflareRequest,
  env : @cloudflare.CloudflareEnv,
  url : @core.Any,
  pathname : String,
  http_method : String,
) -> @http.Response? {
  if pathname == "/oauth/authorize" && http_method == "GET" {
    Some(handle_oauth_authorize(env, url))
  } else if pathname == "/oauth/authorize/verify" && http_method == "POST" {
    Some(handle_oauth_verify(env, req))
  } else {
    None
  }
}

///|
extern "js" fn redirect_response(location : String) -> @http.Response =
  #| (location) => new Response(null, { status: 302, headers: { "Location": location } })

///|
extern "js" fn oauth_now() -> Int =
  #| () => Math.floor(Date.now() / 1000)

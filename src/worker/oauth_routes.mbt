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
  let issuer = match @oauth.canonical_base_url(@config.SITE_URL) {
    Some(value) => value
    None => return json_response("{\"error\":\"server_configuration\"}", 500)
  }
  match (redirect_uri, client) {
    (Some(candidate), Some(metadata)) if metadata.redirect_uri_allowed(
        candidate,
      ) =>
      redirect_response(
        @oauth.authorization_redirect_with_issuer(
          candidate,
          "error",
          error,
          get_search_param(url, "state"),
          issuer,
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
  "if(!r.ok){throw new Error('Passkey verification failed')}location.href=await r.text();" +
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
  let scope_param = get_search_param(url, "scope").unwrap_or("")
  // CIMD client_ids are HTTPS metadata URLs; anything else is resolved
  // against clients stored by RFC 7591 dynamic registration.
  let (client, registered_scope) = if @oauth.validate_client_id_url(client_id) {
    let raw_metadata = match
      @oauth.fetch_client_metadata_document(client_id, @config.SITE_URL, env) {
      Some(value) => value
      None => return json_response("{\"error\":\"invalid_client\"}", 400)
    }
    match @oauth.parse_client_metadata(client_id, raw_metadata) {
      Some(value) => (value, "")
      None => return json_response("{\"error\":\"invalid_client\"}", 400)
    }
  } else {
    let db_value = get_db_from_env(env)
    if @core.typeof_(db_value) == "undefined" || @core.is_null(db_value) {
      return json_response("{\"error\":\"storage_unavailable\"}", 503)
    }
    let db : @cloudflare.D1Database = @core.identity(db_value)
    match @oauth.get_oauth_client(db, client_id) {
      Some(stored) =>
        match @oauth.stored_client_metadata(client_id, stored) {
          Some(value) => (value, stored.scope)
          None => return json_response("{\"error\":\"invalid_client\"}", 400)
        }
      None => return json_response("{\"error\":\"invalid_client\"}", 400)
    }
  }
  if !@oauth.scope_subset(scope_param, registered_scope) {
    return oauth_error_response(url, Some(client), "invalid_scope")
  }
  let request = match
    @oauth.validate_authorization_request(
      get_search_param(url, "response_type").unwrap_or(""),
      client_id,
      get_search_param(url, "redirect_uri").unwrap_or(""),
      get_search_param(url, "resource").unwrap_or(""),
      scope_param,
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
  // Keep the browser timeout aligned with the five-minute OAuth challenge TTL.
  let options = @identity.generate_auth_options_with_timeout(
    kv, user_id, rp_id, 300000,
  )
  let challenge_id = options.challenge_identifier()
  let challenge = options.challenge_value()
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
  let challenge_saved = @oauth.insert_oauth_webauthn_challenge(
    db,
    challenge_id,
    user_id,
    challenge,
    now,
    now + @oauth.OAUTH_WEBAUTHN_CHALLENGE_TTL_SECONDS,
  )
  if !challenge_saved {
    @identity.delete_challenge(kv, user_id, challenge_id)
    return json_response("{\"error\":\"server_error\"}", 500)
  }
  let db_error = @oauth.insert_pending_authorization(db, pending)
  if db_error != "" {
    @oauth.delete_oauth_webauthn_challenge(db, challenge_id, user_id)
    @identity.delete_challenge(kv, user_id, challenge_id)
    return json_response("{\"error\":\"server_error\"}", 500)
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
  let db_value = get_db_from_env(env)
  if @core.typeof_(db_value) == "undefined" || @core.is_null(db_value) {
    return json_response("{\"error\":\"storage_unavailable\"}", 503)
  }
  let db : @cloudflare.D1Database = @core.identity(db_value)
  let now = oauth_now()
  let challenge = match
    @oauth.claim_oauth_webauthn_challenge(db, input.challenge_id, user_id, now) {
    Some(value) => value
    None =>
      return json_response("{\"error\":\"identity_verification_failed\"}", 401)
  }
  @identity.delete_challenge(kv, user_id, input.challenge_id)
  let verify_request = @identity.AuthVerifyRequest::new(
    input.challenge_id,
    input.credential_id,
    input.raw_id,
    input.client_data_json,
    input.authenticator_data,
    input.signature,
  )
  match
    @identity.verify_authentication_with_challenge(
      kv, user_id, rp_id, origin, verify_request, challenge,
    ) {
    @identity.AuthVerifyResult::Success(_) => ()
    @identity.AuthVerifyResult::ChallengeInvalid =>
      return json_response("{\"error\":\"identity_verification_failed\"}", 401)
    @identity.AuthVerifyResult::CredentialNotFound =>
      return json_response("{\"error\":\"identity_verification_failed\"}", 401)
    @identity.AuthVerifyResult::VerificationFailed(_) =>
      return json_response("{\"error\":\"identity_verification_failed\"}", 401)
  }
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
  text_response_js(request.code_redirect_with_issuer(secret, issuer), 200)
}

///|
fn oauth_token_error(error : String, status : Int) -> @http.Response {
  token_json_response("{\"error\":\"" + error + "\"}", status)
}

///|
fn oauth_token_response(
  access_token : String,
  scope : String,
  expires_in : Int,
  refresh_token : String?,
) -> @http.Response {
  let refresh = match refresh_token {
    Some(value) => ",\"refresh_token\":" + json_escape(value)
    None => ""
  }
  token_json_response(
    "{\"token_type\":\"Bearer\",\"access_token\":" +
    json_escape(access_token) +
    ",\"expires_in\":" +
    expires_in.to_string() +
    ",\"scope\":" +
    json_escape(scope) +
    refresh +
    "}",
    200,
  )
}

///|
async fn handle_oauth_token(
  env : @cloudflare.CloudflareEnv,
  req : @cloudflare.CloudflareRequest,
) -> @http.Response {
  let http_req : @http.Request = @core.identity(req)
  if oauth_content_type(req) != "application/x-www-form-urlencoded" {
    return oauth_token_error("invalid_request", 400)
  }
  let request = match @oauth.parse_oauth_token_form(http_req.text()) {
    Some(value) => value
    None => return oauth_token_error("invalid_request", 400)
  }
  let grant_type = request.grant_type()
  if grant_type.is_empty() {
    return oauth_token_error("invalid_request", 400)
  }
  if grant_type != "authorization_code" && grant_type != "refresh_token" {
    return oauth_token_error("unsupported_grant_type", 400)
  }
  let grant = match @oauth.validate_oauth_token_request(request) {
    Some(value) => value
    None => return oauth_token_error("invalid_request", 400)
  }
  let db_value = get_db_from_env(env)
  if @core.typeof_(db_value) == "undefined" || @core.is_null(db_value) {
    return oauth_token_error("server_error", 500)
  }
  let db : @cloudflare.D1Database = @core.identity(db_value)
  let now = oauth_now()
  // Confidential clients registered through RFC 7591 must present their
  // issued secret; unregistered (CIMD) and public clients skip this check.
  let token_client_id = request.client_id().unwrap_or("")
  let presented_secret = match request.client_secret() {
    Some(value) => value
    None => oauth_basic_client_secret(req, token_client_id)
  }
  let stored_client = @oauth.get_oauth_client(db, token_client_id)
  let secret_ok = @oauth.registered_client_secret_ok(
    stored_client, presented_secret,
  )
  if !secret_ok {
    return oauth_token_error("invalid_client", 400)
  }
  match grant {
    @oauth.TokenGrant::AuthorizationCode => {
      let code = request.code().unwrap()
      let client_id = request.client_id().unwrap()
      let redirect_uri = request.redirect_uri().unwrap()
      let resource = request.resource().unwrap()
      let verifier = request.code_verifier().unwrap()
      if !@oauth.validate_opaque_secret(code) {
        return oauth_token_error("invalid_grant", 400)
      }
      let code_hash = @oauth.sha256_hex(code)
      let stored_scope = @oauth.authorization_code_scope(
        db, code_hash, client_id, redirect_uri, resource, verifier, now,
      ) catch {
        _ => return oauth_token_error("server_error", 500)
      }
      let scope = match stored_scope {
        Some(value) => value
        None => return oauth_token_error("invalid_grant", 400)
      }
      let access_token = @oauth.generate_opaque_secret()
      let access_hash = @oauth.sha256_hex(access_token)
      let access = match
        @oauth.access_token_record(
          access_hash,
          client_id,
          resource,
          scope,
          now,
          now + @oauth.ACCESS_TOKEN_TTL_SECONDS,
        ) {
        Some(value) => value
        None => return oauth_token_error("server_error", 500)
      }
      let refresh_token : String? = if @oauth.scope_contains(
          scope,
          @oauth.SCOPE_OFFLINE_ACCESS,
        ) {
        Some(@oauth.generate_opaque_secret())
      } else {
        None
      }
      let refresh = match refresh_token {
        Some(value) => {
          let hash = @oauth.sha256_hex(value)
          match
            @oauth.refresh_token_record(
              hash,
              hash,
              client_id,
              resource,
              scope,
              now,
              now + @oauth.REFRESH_TOKEN_TTL_SECONDS,
            ) {
            Some(record) => Some(record)
            None => return oauth_token_error("server_error", 500)
          }
        }
        None => None
      }
      let redeemed = @oauth.redeem_authorization_code_with_tokens(
        db, code_hash, client_id, redirect_uri, resource, verifier, now, access,
        refresh,
      ) catch {
        _ => return oauth_token_error("server_error", 500)
      }
      match redeemed {
        @oauth.RedeemAuthorizationCodeResult::AuthorizationCodeInvalid =>
          oauth_token_error("invalid_grant", 400)
        @oauth.RedeemAuthorizationCodeResult::AuthorizationCodeRedeemed(_) =>
          oauth_token_response(
            access_token,
            scope,
            @oauth.ACCESS_TOKEN_TTL_SECONDS,
            refresh_token,
          )
      }
    }
    @oauth.TokenGrant::RefreshToken => {
      let old_token = request.refresh_token().unwrap()
      let client_id = request.client_id().unwrap()
      let resource = request.resource().unwrap()
      if !@oauth.validate_opaque_secret(old_token) {
        return oauth_token_error("invalid_grant", 400)
      }
      let old_hash = @oauth.sha256_hex(old_token)
      let current = @oauth.lookup_refresh_token(
        db, old_hash, client_id, resource, now,
      ) catch {
        _ => return oauth_token_error("server_error", 500)
      }
      match current {
        Some(current) => {
          let scope = current.scope()
          let replacement = @oauth.generate_opaque_secret()
          let replacement_hash = @oauth.sha256_hex(replacement)
          let access_token = @oauth.generate_opaque_secret()
          let access_hash = @oauth.sha256_hex(access_token)
          let access = match
            @oauth.access_token_record(
              access_hash,
              client_id,
              resource,
              scope,
              now,
              now + @oauth.ACCESS_TOKEN_TTL_SECONDS,
            ) {
            Some(value) => value
            None => return oauth_token_error("server_error", 500)
          }
          let rotation = @oauth.rotate_refresh_token_with_access(
            db,
            old_hash,
            client_id,
            resource,
            replacement_hash,
            now,
            now + @oauth.REFRESH_TOKEN_TTL_SECONDS,
            now,
            access,
          ) catch {
            _ => return oauth_token_error("server_error", 500)
          }
          match rotation {
            @oauth.RefreshRotationDecision::RefreshReplay => {
              @oauth.revoke_refresh_family_for_token(
                db, old_hash, client_id, resource, now,
              ) catch {
                _ => return oauth_token_error("server_error", 500)
              }
              oauth_token_error("invalid_grant", 400)
            }
            @oauth.RefreshRotationDecision::RefreshInvalid =>
              oauth_token_error("invalid_grant", 400)
            @oauth.RefreshRotationDecision::RefreshRotated =>
              oauth_token_response(
                access_token,
                scope,
                @oauth.ACCESS_TOKEN_TTL_SECONDS,
                Some(replacement),
              )
          }
        }
        None => {
          let replay = @oauth.refresh_token_replay_detected(
            db, old_hash, client_id, resource,
          ) catch {
            _ => return oauth_token_error("server_error", 500)
          }
          if replay {
            @oauth.revoke_refresh_family_for_token(
              db, old_hash, client_id, resource, now,
            ) catch {
              _ => return oauth_token_error("server_error", 500)
            }
            oauth_token_error("invalid_grant", 400)
          } else {
            oauth_token_error("invalid_grant", 400)
          }
        }
      }
    }
  }
}

///|
/// RFC 7591 registration: validate the client metadata, persist the client,
/// and return the issued identifier (plus the secret for confidential
/// clients). The response uses the token response writer so it gets
/// JSON + no-store caching headers.
async fn handle_oauth_register(
  env : @cloudflare.CloudflareEnv,
  req : @cloudflare.CloudflareRequest,
) -> @http.Response {
  if oauth_content_type(req) != "application/json" {
    return json_response("{\"error\":\"invalid_client_metadata\"}", 400)
  }
  let http_req : @http.Request = @core.identity(req)
  let registration = match @oauth.parse_client_registration(http_req.text()) {
    Some(value) => value
    None => return json_response("{\"error\":\"invalid_client_metadata\"}", 400)
  }
  let db_value = get_db_from_env(env)
  if @core.typeof_(db_value) == "undefined" || @core.is_null(db_value) {
    return json_response("{\"error\":\"server_error\"}", 500)
  }
  let db : @cloudflare.D1Database = @core.identity(db_value)
  let now = oauth_now()
  let client_id = "dcr-" + @oauth.generate_opaque_secret()
  let client_secret : String? = if registration.requires_secret() {
    Some(@oauth.generate_opaque_secret())
  } else {
    None
  }
  let secret_hash : String? = match client_secret {
    Some(secret) => Some(@oauth.sha256_hex(secret))
    None => None
  }
  let stored = @oauth.insert_oauth_client(
    db,
    registration.record(client_id, secret_hash, now),
  )
  if !stored {
    return json_response("{\"error\":\"server_error\"}", 500)
  }
  token_json_response(
    registration.response_json(client_id, client_secret, now),
    201,
  )
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
  } else if pathname == "/oauth/token" && http_method == "POST" {
    Some(handle_oauth_token(env, req))
  } else if pathname == "/oauth/register" && http_method == "POST" {
    Some(handle_oauth_register(env, req))
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

///|
extern "js" fn oauth_content_type(
  req : @cloudflare.CloudflareRequest,
) -> String =
  #| (request) => (request.headers.get("content-type") || "").split(";", 1)[0].trim().toLowerCase()

///|
/// Extract the client_secret from HTTP Basic authentication for token
/// endpoint client authentication. Both sides of the credential are
/// form-decoded per RFC 6749; an empty string means no usable credential.
extern "js" fn oauth_basic_client_secret(
  req : @cloudflare.CloudflareRequest,
  client_id : String,
) -> String =
  #| (request, clientId) => {
  #|   const header = request.headers.get("authorization") || "";
  #|   if (!header.toLowerCase().startsWith("basic ")) return "";
  #|   try {
  #|     const decoded = atob(header.slice(6).trim());
  #|     const separator = decoded.indexOf(":");
  #|     if (separator < 0) return "";
  #|     let id = decoded.slice(0, separator);
  #|     let secret = decoded.slice(separator + 1);
  #|     try { id = decodeURIComponent(id); } catch (_) {}
  #|     try { secret = decodeURIComponent(secret); } catch (_) {}
  #|     if (id !== clientId) return "";
  #|     return secret;
  #|   } catch (_) {
  #|     return "";
  #|   }
  #| }

///|
extern "js" fn token_json_response(
  body : String,
  status : Int,
) -> @http.Response =
  #| (body, status) => new Response(body, { status, headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store", "Pragma": "no-cache" } })

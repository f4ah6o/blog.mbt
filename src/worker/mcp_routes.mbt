///|
const MCP_MAX_BODY_BYTES : Int = 1048576

///|
const MCP_SERVER_NAME : String = "f4ah6o/blog.mbt"

///|
const MCP_SERVER_VERSION : String = "0.1.0"

///|
pub fn mcp_auth_status(decision : @oauth.ProtectedResourceAuthorization) -> Int {
  match decision {
    @oauth.ProtectedResourceAuthorization::Authorized(_) => 200
    @oauth.ProtectedResourceAuthorization::MissingToken => 401
    @oauth.ProtectedResourceAuthorization::InvalidToken => 401
    @oauth.ProtectedResourceAuthorization::InsufficientScope => 403
    @oauth.ProtectedResourceAuthorization::InvalidConfiguration => 500
    @oauth.ProtectedResourceAuthorization::ServerError => 500
  }
}

///|
pub fn mcp_auth_challenge_error(
  decision : @oauth.ProtectedResourceAuthorization,
) -> String? {
  match decision {
    @oauth.ProtectedResourceAuthorization::MissingToken => None
    @oauth.ProtectedResourceAuthorization::InvalidToken => Some("invalid_token")
    @oauth.ProtectedResourceAuthorization::InsufficientScope =>
      Some("insufficient_scope")
    _ => None
  }
}

///|
pub fn mcp_http_preflight_status(
  http_method : String,
  content_type : String,
  accept : String,
) -> Int {
  if http_method != "POST" {
    405
  } else if content_type != "application/json" {
    415
  } else if !@mcp.valid_streamable_http_accept(accept) {
    406
  } else {
    200
  }
}

///|
fn mcp_protocol_headers(
  req : @cloudflare.CloudflareRequest,
) -> @mcp.HttpHeaders {
  let entries : Array[(String, String)] = []
  match mcp_request_header(req, @mcp.MCP_PROTOCOL_VERSION_HEADER) {
    Some(value) => entries.push((@mcp.MCP_PROTOCOL_VERSION_HEADER, value))
    None => ()
  }
  match mcp_request_header(req, @mcp.MCP_METHOD_HEADER) {
    Some(value) => entries.push((@mcp.MCP_METHOD_HEADER, value))
    None => ()
  }
  match mcp_request_header(req, @mcp.MCP_NAME_HEADER) {
    Some(value) => entries.push((@mcp.MCP_NAME_HEADER, value))
    None => ()
  }
  @mcp.HttpHeaders::new(entries)
}

///|
pub async fn handle_mcp_request(
  req : @cloudflare.CloudflareRequest,
  env : @cloudflare.CloudflareEnv,
  pathname : String,
  http_method : String,
) -> @http.Response? {
  if pathname != "/mcp" {
    return None
  }
  let content_type = mcp_content_type(req)
  let accept = mcp_request_header(req, "Accept").unwrap_or("")
  let preflight = mcp_http_preflight_status(http_method, content_type, accept)
  if preflight != 200 {
    return Some(mcp_empty_response_js(preflight, "", preflight == 405))
  }
  let db_value = get_db_from_env(env)
  if @core.typeof_(db_value) == "undefined" || @core.is_null(db_value) {
    return Some(mcp_empty_response_js(503, "", false))
  }
  let db : @cloudflare.D1Database = @core.identity(db_value)
  let authorization = mcp_request_header(req, "Authorization")
  let auth = @oauth.authorize_protected_resource(
    db,
    @config.SITE_URL,
    authorization,
    @oauth.SCOPE_MCP_DISCOVER,
    mcp_now(),
  ) catch {
    _ => @oauth.ProtectedResourceAuthorization::ServerError
  }
  let auth_status = mcp_auth_status(auth)
  if auth_status != 200 {
    let challenge = match
      @oauth.protected_resource_challenge(
        @config.SITE_URL,
        @oauth.SCOPE_MCP_DISCOVER,
        mcp_auth_challenge_error(auth),
      ) {
      Some(value) if auth_status == 401 || auth_status == 403 => value
      _ => ""
    }
    return Some(mcp_empty_response_js(auth_status, challenge, false))
  }
  let http_req : @http.Request = @core.identity(req)
  let body = http_req.text()
  if mcp_utf8_length(body) > MCP_MAX_BODY_BYTES {
    return Some(mcp_empty_response_js(413, "", false))
  }
  let result = @mcp.dispatch_mcp_http_request(
    body,
    mcp_protocol_headers(req),
    MCP_SERVER_NAME,
    MCP_SERVER_VERSION,
  )
  Some(mcp_json_response_js(result.body(), result.status()))
}

///|
extern "js" fn mcp_request_header(
  req : @cloudflare.CloudflareRequest,
  name : String,
) -> String? =
  #| (request, name) => {
  #|   const value = request.headers.get(name)
  #|   return value === null ? undefined : value
  #| }

///|
extern "js" fn mcp_content_type(req : @cloudflare.CloudflareRequest) -> String =
  #| (request) => (request.headers.get("content-type") || "").split(";", 1)[0].trim().toLowerCase()

///|
extern "js" fn mcp_utf8_length(body : String) -> Int =
  #| (body) => new TextEncoder().encode(body).byteLength

///|
extern "js" fn mcp_now() -> Int =
  #| () => Math.floor(Date.now() / 1000)

///|
extern "js" fn mcp_json_response_js(
  body : String,
  status : Int,
) -> @http.Response =
  #| (body, status) => new Response(body, {
  #|   status,
  #|   headers: { "Content-Type": "application/json; charset=utf-8" },
  #| })

///|
extern "js" fn mcp_empty_response_js(
  status : Int,
  challenge : String,
  allow_post : Bool,
) -> @http.Response =
  #| (status, challenge, allowPost) => {
  #|   const headers = new Headers()
  #|   if (challenge) headers.set("WWW-Authenticate", challenge)
  #|   if (allowPost) headers.set("Allow", "POST")
  #|   return new Response(null, { status, headers })
  #| }

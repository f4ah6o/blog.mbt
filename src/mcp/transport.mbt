///|
/// Pure protocol-layer result consumed by the Cloudflare Worker bridge. HTTP
/// object construction stays outside this package; status/body semantics stay
/// here in MoonBit.
pub struct McpHttpResult {
  priv status : Int
  priv body : String
}

///|
pub fn McpHttpResult::status(self : McpHttpResult) -> Int {
  self.status
}

///|
pub fn McpHttpResult::body(self : McpHttpResult) -> String {
  self.body
}

///|
fn mcp_http_result(status : Int, body : String) -> McpHttpResult {
  { status, body, }
}

///|
/// Validate and dispatch one independent MCP 2026-07-28 POST body. The
/// transport is intentionally stateless: no initialize handshake or session
/// identifier participates in dispatch.
pub fn dispatch_mcp_http_request(
  body : String,
  headers : HttpHeaders,
  server_name : String,
  server_version : String,
) -> McpHttpResult {
  let request = match validate_mcp_http_request(body, headers) {
    Ok(value) => value
    Err(error) => return mcp_http_result(400, error.to_json_string())
  }
  // The 2026-07-28 core defines no client-to-server notifications over
  // Streamable HTTP. Reject rather than silently accepting a method whose
  // request schema requires an id.
  if request.is_notification() {
    let error = JsonRpcError::new(
      JSON_RPC_INVALID_REQUEST,
      "Invalid Request: client notifications are not supported over MCP 2026-07-28 Streamable HTTP",
    )
    return mcp_http_result(
      400,
      JsonRpcErrorResponse::new(null, error).to_json_string(),
    )
  }
  if request.method_name() == "server/discover" {
    return mcp_http_result(
      200,
      server_discover_response(
        request.id_or_null(),
        server_name,
        server_version,
      ),
    )
  }
  if request.method_name() == "tools/list" {
    match
      tools_list_response(
        request.id_or_null(),
        request.params(),
        server_name,
        server_version,
      ) {
      Ok(body) => return mcp_http_result(200, body)
      Err(error) =>
        return mcp_http_result(
          400,
          JsonRpcErrorResponse::new(request.id_or_null(), error).to_json_string(),
        )
    }
  }
  let error = JsonRpcError::new(JSON_RPC_METHOD_NOT_FOUND, "Method not found")
  mcp_http_result(
    404,
    JsonRpcErrorResponse::new(request.id_or_null(), error).to_json_string(),
  )
}

///|
/// Streamable HTTP clients must advertise support for both response forms.
/// Parameters on either media type are tolerated; comparison is
/// case-insensitive as media types are case-insensitive.
pub fn valid_streamable_http_accept(value : String) -> Bool {
  let mut json = false
  let mut event_stream = false
  for item in value.to_lower().split(",") {
    let media = item.to_owned().trim().to_owned()
    let mut base = media
    for part in base.split(";") {
      base = part.to_owned().trim().to_owned()
      break
    }
    if base == "application/json" {
      json = true
    } else if base == "text/event-stream" {
      event_stream = true
    }
  }
  json && event_stream
}

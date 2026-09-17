///|
/// Reverse-DNS `_meta` keys used by MCP 2026-07-28 request envelopes.
pub const MCP_PROTOCOL_VERSION_META_KEY : String = "io.modelcontextprotocol/protocolVersion"

///|
pub const MCP_CLIENT_INFO_META_KEY : String = "io.modelcontextprotocol/clientInfo"

///|
pub const MCP_CAPABILITIES_META_KEY : String = "io.modelcontextprotocol/capabilities"

///|
/// A validated stateless MCP 2026-07-28 request: a JSON-RPC request plus the
/// required per-request `_meta` protocol version. `clientInfo`/`capabilities`
/// are accepted when present but are self-reported and MUST NOT be used for
/// authentication or authorization. Instances are produced only by
/// `parse_mcp_request`.
pub struct McpRequest {
  priv request : JsonRpcRequest
  priv meta : Json
  priv protocol_version : String
}

///|
pub fn McpRequest::method_name(self : McpRequest) -> String {
  self.request.method_name()
}

///|
pub fn McpRequest::id_json(self : McpRequest) -> Json? {
  self.request.id_json()
}

///|
pub fn McpRequest::id_or_null(self : McpRequest) -> Json {
  self.request.id_or_null()
}

///|
pub fn McpRequest::is_notification(self : McpRequest) -> Bool {
  self.request.is_notification()
}

///|
pub fn McpRequest::params(self : McpRequest) -> Json? {
  self.request.params()
}

///|
pub fn McpRequest::protocol_version(self : McpRequest) -> String {
  self.protocol_version
}

///|
pub fn McpRequest::meta(self : McpRequest) -> Json {
  self.meta
}

///|
/// The optional, self-reported client info object. Never authoritative.
pub fn McpRequest::client_info(self : McpRequest) -> Json? {
  match self.meta {
    Object(meta) => meta.get(MCP_CLIENT_INFO_META_KEY)
    _ => None
  }
}

///|
/// The optional, self-reported client capabilities object. Never authoritative.
pub fn McpRequest::client_capabilities(self : McpRequest) -> Json? {
  match self.meta {
    Object(meta) => meta.get(MCP_CAPABILITIES_META_KEY)
    _ => None
  }
}

///|
fn param_string(params : Json?, key : String) -> String? {
  match params {
    Some(Object(obj)) =>
      match obj.get(key) {
        Some(String(value)) => Some(value)
        _ => None
      }
    _ => None
  }
}

///|
/// The value a required `Mcp-Name` header must mirror, derived from the body.
pub fn McpRequest::body_target(self : McpRequest) -> String? {
  match mcp_name_source(self.method_name()) {
    ParamName => param_string(self.params(), "name")
    ParamUri => param_string(self.params(), "uri")
    NoName => None
  }
}

///|
/// Parse a JSON-RPC request and require the MCP 2026-07-28 `params._meta`
/// protocol version. Missing, malformed, or unsupported metadata fails closed
/// as `-32600` invalid request.
pub fn parse_mcp_request(body : String) -> Result[McpRequest, JsonRpcError] {
  let request = match parse_json_rpc_request(body) {
    Ok(request) => request
    Err(error) => return Err(error)
  }
  let params = match request.params() {
    Some(Object(obj)) => obj
    _ =>
      return Err(
        JsonRpcError::new(
          JSON_RPC_INVALID_REQUEST,
          "Invalid Request: params object with _meta is required",
        ),
      )
  }
  let meta_json = match params.get("_meta") {
    Some(value) =>
      match value {
        Object(_) => value
        _ =>
          return Err(
            JsonRpcError::new(
              JSON_RPC_INVALID_REQUEST,
              "Invalid Request: params._meta object is required",
            ),
          )
      }
    _ =>
      return Err(
        JsonRpcError::new(
          JSON_RPC_INVALID_REQUEST,
          "Invalid Request: params._meta object is required",
        ),
      )
  }
  let meta = match meta_json {
    Object(obj) => obj
    _ =>
      return Err(
        JsonRpcError::new(
          JSON_RPC_INVALID_REQUEST,
          "Invalid Request: params._meta object is required",
        ),
      )
  }
  let protocol_version = match meta.get(MCP_PROTOCOL_VERSION_META_KEY) {
    Some(String(value)) => value
    _ =>
      return Err(
        JsonRpcError::new(
          JSON_RPC_INVALID_REQUEST,
          "Invalid Request: params._meta." +
          MCP_PROTOCOL_VERSION_META_KEY +
          " is required",
        ),
      )
  }
  if protocol_version != MCP_PROTOCOL_VERSION {
    return Err(
      JsonRpcError::new(
        JSON_RPC_INVALID_REQUEST,
        "Invalid Request: unsupported protocol version " + protocol_version,
      ),
    )
  }
  match meta.get(MCP_CLIENT_INFO_META_KEY) {
    None => ()
    Some(Object(_)) => ()
    Some(_) =>
      return Err(
        JsonRpcError::new(
          JSON_RPC_INVALID_REQUEST,
          "Invalid Request: params._meta." +
          MCP_CLIENT_INFO_META_KEY +
          " must be an object",
        ),
      )
  }
  match meta.get(MCP_CAPABILITIES_META_KEY) {
    None => ()
    Some(Object(_)) => ()
    Some(_) =>
      return Err(
        JsonRpcError::new(
          JSON_RPC_INVALID_REQUEST,
          "Invalid Request: params._meta." +
          MCP_CAPABILITIES_META_KEY +
          " must be an object",
        ),
      )
  }
  Ok(McpRequest::{ request, meta: meta_json, protocol_version, })
}

///|
/// Validate the three MCP standard headers in protocol order. Returns `None`
/// only when every required header is present and agrees with the body.
pub fn McpRequest::validate_headers(
  self : McpRequest,
  headers : HttpHeaders,
) -> McpHeaderError? {
  match validate_protocol_version_header(headers, self.protocol_version) {
    Some(error) => Some(error)
    None =>
      match validate_method_header(headers, self.method_name()) {
        Some(error) => Some(error)
        None =>
          validate_name_header(headers, self.method_name(), self.body_target())
      }
  }
}

///|
/// Full stateless validation pipeline: JSON-RPC envelope, required `_meta`
/// protocol version, then the MCP standard headers. Envelope failures keep
/// their standard JSON-RPC code; header failures become `-32020`. The returned
/// error response already carries the id recovered from a valid body.
pub fn validate_mcp_http_request(
  body : String,
  headers : HttpHeaders,
) -> Result[McpRequest, JsonRpcErrorResponse] {
  let request = match parse_mcp_request(body) {
    Ok(request) => request
    Err(error) => return Err(JsonRpcErrorResponse::new(null, error))
  }
  match request.validate_headers(headers) {
    Some(error) =>
      Err(
        JsonRpcErrorResponse::new(
          request.id_or_null(),
          error.to_json_rpc_error(),
        ),
      )
    None => Ok(request)
  }
}

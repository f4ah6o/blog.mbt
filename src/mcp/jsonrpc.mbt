///|
/// Standard JSON-RPC 2.0 error codes. The MCP revision reuses JSON-RPC error
/// objects, so these stay plain `Int` constants.
pub const JSON_RPC_PARSE_ERROR : Int = -32700

///|
pub const JSON_RPC_INVALID_REQUEST : Int = -32600

///|
pub const JSON_RPC_METHOD_NOT_FOUND : Int = -32601

///|
pub const JSON_RPC_INVALID_PARAMS : Int = -32602

///|
pub const JSON_RPC_INTERNAL_ERROR : Int = -32603

///|
/// MCP 2026-07-28 `HeaderMismatch` (SEP-2243, reassigned to -32020).
pub const MCP_HEADER_MISMATCH : Int = -32020

///|
pub const JSON_RPC_VERSION : String = "2.0"

///|
/// The only protocol version this package models. The 2026-07-28 revision is
/// stateless: there is no `initialize` handshake and no `Mcp-Session-Id`.
pub const MCP_PROTOCOL_VERSION : String = "2026-07-28"

///|
/// A JSON-RPC 2.0 error object. `data` is optional and, when present, is
/// echoed verbatim. This type deliberately does not derive `Eq`/`Debug`
/// because the builtin `Json` type implements neither.
pub struct JsonRpcError {
  priv code : Int
  priv message : String
  priv data : Json?
}

///|
pub fn JsonRpcError::new(code : Int, message : String) -> JsonRpcError {
  { code, message, data: None, }
}

///|
pub fn JsonRpcError::with_data(
  code : Int,
  message : String,
  data : Json,
) -> JsonRpcError {
  { code, message, data: Some(data), }
}

///|
pub fn JsonRpcError::code(self : JsonRpcError) -> Int {
  self.code
}

///|
pub fn JsonRpcError::message(self : JsonRpcError) -> String {
  self.message
}

///|
pub fn JsonRpcError::data(self : JsonRpcError) -> Json? {
  self.data
}

///|
pub fn JsonRpcError::to_json(self : JsonRpcError) -> Json {
  match self.data {
    Some(data) =>
      ({ "code": self.code, "message": self.message, "data": data } : Json)
    None => ({ "code": self.code, "message": self.message } : Json)
  }
}

///|
pub fn JsonRpcError::to_json_string(self : JsonRpcError) -> String {
  self.to_json().stringify()
}

///|
/// The JSON-preserved shape of a request id. `IdMissing` is a notification.
pub(all) enum JsonRpcIdKind {
  IdMissing
  IdNull
  IdString
  IdNumber
  IdInvalid
} derive(Eq, Debug)

///|
/// A parsed JSON-RPC 2.0 request. `id` is retained as raw `Json` so the
/// original string/number distinction survives re-serialization. Instances are
/// produced only by `parse_json_rpc_request`, so every field invariant holds.
pub struct JsonRpcRequest {
  priv id : Json?
  priv method_name : String
  priv params : Json?
}

///|
pub fn JsonRpcRequest::id_json(self : JsonRpcRequest) -> Json? {
  self.id
}

///|
/// The id to echo in a response; notifications echo `null`.
pub fn JsonRpcRequest::id_or_null(self : JsonRpcRequest) -> Json {
  match self.id {
    Some(value) => value
    None => null
  }
}

///|
pub fn JsonRpcRequest::id_kind(self : JsonRpcRequest) -> JsonRpcIdKind {
  match self.id {
    None => IdMissing
    Some(Null) => IdNull
    Some(String(_)) => IdString
    Some(Number(_, ..)) => IdNumber
    Some(_) => IdInvalid
  }
}

///|
pub fn JsonRpcRequest::method_name(self : JsonRpcRequest) -> String {
  self.method_name
}

///|
pub fn JsonRpcRequest::params(self : JsonRpcRequest) -> Json? {
  self.params
}

///|
pub fn JsonRpcRequest::is_notification(self : JsonRpcRequest) -> Bool {
  match self.id {
    None => true
    Some(_) => false
  }
}

///|
fn valid_json_rpc_id(id : Json) -> Bool {
  match id {
    Null => true
    String(_) => true
    Number(_, ..) => true
    _ => false
  }
}

///|
/// Parse and validate a JSON-RPC 2.0 request envelope, fail-closed:
/// - malformed JSON maps to `-32700`,
/// - anything that is not a request object maps to `-32600`,
/// - response-shaped bodies (`result`/`error`) are rejected rather than
///   silently treated as requests.
pub fn parse_json_rpc_request(
  body : String,
) -> Result[JsonRpcRequest, JsonRpcError] {
  let json = @json.parse(body) catch {
    _ => return Err(JsonRpcError::new(JSON_RPC_PARSE_ERROR, "Parse error"))
  }
  let obj = match json {
    Object(obj) => obj
    _ =>
      return Err(
        JsonRpcError::new(
          JSON_RPC_INVALID_REQUEST,
          "Invalid Request: body must be a JSON object",
        ),
      )
  }
  if obj.get("result") is Some(_) {
    return Err(
      JsonRpcError::new(
        JSON_RPC_INVALID_REQUEST,
        "Invalid Request: response envelopes are not requests",
      ),
    )
  }
  if obj.get("error") is Some(_) {
    return Err(
      JsonRpcError::new(
        JSON_RPC_INVALID_REQUEST,
        "Invalid Request: response envelopes are not requests",
      ),
    )
  }
  match obj.get("jsonrpc") {
    Some(String(version)) if version == JSON_RPC_VERSION => ()
    _ =>
      return Err(
        JsonRpcError::new(
          JSON_RPC_INVALID_REQUEST,
          "Invalid Request: jsonrpc must be \"2.0\"",
        ),
      )
  }
  let method_name = match obj.get("method") {
    Some(String(value)) if !value.is_empty() => value
    _ =>
      return Err(
        JsonRpcError::new(
          JSON_RPC_INVALID_REQUEST,
          "Invalid Request: method must be a non-empty string",
        ),
      )
  }
  let id = match obj.get("id") {
    None => None
    Some(value) =>
      if valid_json_rpc_id(value) {
        Some(value)
      } else {
        return Err(
          JsonRpcError::new(
            JSON_RPC_INVALID_REQUEST,
            "Invalid Request: id must be a string, number, or null",
          ),
        )
      }
  }
  let params = match obj.get("params") {
    None => None
    Some(value) =>
      match value {
        Object(_) => Some(value)
        Array(_) => Some(value)
        _ =>
          return Err(
            JsonRpcError::new(
              JSON_RPC_INVALID_REQUEST,
              "Invalid Request: params must be an object or array",
            ),
          )
      }
  }
  Ok(JsonRpcRequest::{ id, method_name, params, })
}

///|
/// Build a JSON-RPC error response object with the request id echoed back.
pub fn json_rpc_error_response(id : Json, error : JsonRpcError) -> Json {
  ({ "jsonrpc": JSON_RPC_VERSION, "id": id, "error": error.to_json() } : Json)
}

///|
pub fn json_rpc_error_response_string(
  id : Json,
  error : JsonRpcError,
) -> String {
  json_rpc_error_response(id, error).stringify()
}

///|
/// A JSON-RPC error response with the request id already resolved. `id` is
/// `null` when the id could not be recovered from the request body.
pub struct JsonRpcErrorResponse {
  priv id : Json
  priv error : JsonRpcError
}

///|
pub fn JsonRpcErrorResponse::new(
  id : Json,
  error : JsonRpcError,
) -> JsonRpcErrorResponse {
  { id, error, }
}

///|
pub fn JsonRpcErrorResponse::id(self : JsonRpcErrorResponse) -> Json {
  self.id
}

///|
pub fn JsonRpcErrorResponse::error(self : JsonRpcErrorResponse) -> JsonRpcError {
  self.error
}

///|
pub fn JsonRpcErrorResponse::to_json(self : JsonRpcErrorResponse) -> Json {
  json_rpc_error_response(self.id, self.error)
}

///|
pub fn JsonRpcErrorResponse::to_json_string(
  self : JsonRpcErrorResponse,
) -> String {
  self.to_json().stringify()
}

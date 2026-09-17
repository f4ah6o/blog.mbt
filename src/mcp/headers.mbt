///|
/// Standard Streamable HTTP header names for MCP 2026-07-28. Header names are
/// case-insensitive; values are not.
pub const MCP_PROTOCOL_VERSION_HEADER : String = "MCP-Protocol-Version"

///|
pub const MCP_METHOD_HEADER : String = "Mcp-Method"

///|
pub const MCP_NAME_HEADER : String = "Mcp-Name"

///|
/// An ordered, duplicate-preserving header list. Lookup is case-insensitive
/// and trims optional whitespace from values, matching HTTP field parsing.
pub struct HttpHeaders {
  priv entries : Array[(String, String)]
}

///|
pub fn HttpHeaders::new(entries : Array[(String, String)]) -> HttpHeaders {
  { entries, }
}

///|
pub fn HttpHeaders::empty() -> HttpHeaders {
  { entries: [], }
}

///|
pub fn HttpHeaders::get(self : HttpHeaders, name : String) -> String? {
  let wanted = name.to_lower()
  for entry in self.entries {
    let (key, value) = entry
    if key.to_lower() == wanted {
      return Some(value.trim().to_owned())
    }
  }
  None
}

///|
/// Where the `Mcp-Name` header is mirrored from, when it is required.
pub(all) enum McpNameSource {
  NoName
  ParamName
  ParamUri
} derive(Eq, Debug)

///|
/// SEP-2243 requires `Mcp-Name` only for requests that target a specific
/// object: `tools/call` and `prompts/get` use `params.name`, while
/// `resources/read` uses `params.uri`.
pub fn mcp_name_source(method_name : String) -> McpNameSource {
  match method_name {
    "tools/call" => ParamName
    "prompts/get" => ParamName
    "resources/read" => ParamUri
    _ => NoName
  }
}

///|
fn mcp_name_source_field(source : McpNameSource) -> String {
  match source {
    ParamName => "params.name"
    ParamUri => "params.uri"
    NoName => ""
  }
}

///|
/// A Streamable HTTP standard-header validation failure. Every variant maps to
/// JSON-RPC `-32020` `HeaderMismatch` on the wire.
pub(all) enum McpHeaderError {
  MissingHeader(String)
  HeaderValueMismatch(String, String, String)
  MissingBodyValue(String, String, McpNameSource)
  UnexpectedHeader(String, String, String)
} derive(Eq, Debug)

///|
pub fn McpHeaderError::to_json_rpc_error(self : McpHeaderError) -> JsonRpcError {
  let message = match self {
    MissingHeader(header) =>
      "Header mismatch: required header " + header + " is missing"
    HeaderValueMismatch(header, body_value, header_value) =>
      "Header mismatch: " +
      header +
      " header value '" +
      header_value +
      "' does not match body value '" +
      body_value +
      "'"
    MissingBodyValue(header, method_name, source) =>
      "Header mismatch: " +
      header +
      " is required for " +
      method_name +
      " but the body does not carry " +
      mcp_name_source_field(source)
    UnexpectedHeader(header, method_name, value) =>
      "Header mismatch: " +
      header +
      " must not be sent for " +
      method_name +
      " (received '" +
      value +
      "')"
  }
  JsonRpcError::new(MCP_HEADER_MISMATCH, message)
}

///|
/// The `MCP-Protocol-Version` header is required and must agree with the
/// version carried in the request body `_meta`.
pub fn validate_protocol_version_header(
  headers : HttpHeaders,
  body_version : String,
) -> McpHeaderError? {
  match headers.get(MCP_PROTOCOL_VERSION_HEADER) {
    None => Some(MissingHeader(MCP_PROTOCOL_VERSION_HEADER))
    Some(header_version) =>
      if header_version == body_version {
        None
      } else {
        Some(
          HeaderValueMismatch(
            MCP_PROTOCOL_VERSION_HEADER,
            body_version,
            header_version,
          ),
        )
      }
  }
}

///|
/// The `Mcp-Method` header is required and must agree with the JSON-RPC method.
pub fn validate_method_header(
  headers : HttpHeaders,
  body_method : String,
) -> McpHeaderError? {
  match headers.get(MCP_METHOD_HEADER) {
    None => Some(MissingHeader(MCP_METHOD_HEADER))
    Some(header_method) =>
      if header_method == body_method {
        None
      } else {
        Some(HeaderValueMismatch(MCP_METHOD_HEADER, body_method, header_method))
      }
  }
}

///|
/// Validate `Mcp-Name` only for the methods that target a named object. Values
/// are compared byte-for-byte; header whitespace was already trimmed by
/// `HttpHeaders::get`.
pub fn validate_name_header(
  headers : HttpHeaders,
  method_name : String,
  body_value : String?,
) -> McpHeaderError? {
  let source = mcp_name_source(method_name)
  if source is NoName {
    return match headers.get(MCP_NAME_HEADER) {
      None => None
      Some(value) => Some(UnexpectedHeader(MCP_NAME_HEADER, method_name, value))
    }
  }
  match body_value {
    None => Some(MissingBodyValue(MCP_NAME_HEADER, method_name, source))
    Some(target) =>
      match headers.get(MCP_NAME_HEADER) {
        None => Some(MissingHeader(MCP_NAME_HEADER))
        Some(header_value) =>
          if header_value == target {
            None
          } else {
            Some(HeaderValueMismatch(MCP_NAME_HEADER, target, header_value))
          }
      }
  }
}

///|
fn expect_request(body : String) -> JsonRpcRequest {
  match parse_json_rpc_request(body) {
    Ok(request) => request
    Err(_) => panic()
  }
}

///|
fn expect_mcp_request(body : String) -> McpRequest {
  match parse_mcp_request(body) {
    Ok(request) => request
    Err(_) => panic()
  }
}

///|
test "json-rpc request preserves numeric and string ids" {
  let numeric = expect_request(
    (
      #|{"jsonrpc":"2.0","id":7,"method":"tools/list","params":{}}
    ),
  )
  assert_eq(numeric.method_name(), "tools/list")
  assert_eq(numeric.id_kind(), IdNumber)
  match numeric.id_json() {
    Some(Number(value, ..)) => assert_eq(value, 7.0)
    _ => panic()
  }
  let textual = expect_request(
    (
      #|{"jsonrpc":"2.0","id":"abc","method":"tools/list","params":{}}
    ),
  )
  assert_eq(textual.id_kind(), IdString)
  match textual.id_json() {
    Some(String(value)) => assert_eq(value, "abc")
    _ => panic()
  }
}

///|
test "json-rpc notification has no id" {
  let notification = expect_request(
    (
      #|{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}
    ),
  )
  assert_eq(notification.is_notification(), true)
  assert_eq(notification.id_kind(), IdMissing)
  match notification.id_or_null() {
    Null => ()
    _ => panic()
  }
}

///|
test "malformed json maps to parse error" {
  match parse_json_rpc_request("{") {
    Ok(_) => panic()
    Err(error) => assert_eq(error.code(), JSON_RPC_PARSE_ERROR)
  }
}

///|
test "non-object bodies are invalid requests" {
  for body in ["[]", "\"hello\"", "42", "null", "true"] {
    match parse_json_rpc_request(body) {
      Ok(_) => panic()
      Err(error) => assert_eq(error.code(), JSON_RPC_INVALID_REQUEST)
    }
  }
}

///|
test "response envelopes are rejected as requests" {
  let result_body =
    #|{"jsonrpc":"2.0","id":1,"result":{}}
  let error_body =
    #|{"jsonrpc":"2.0","id":1,"error":{"code":-32603,"message":"x"}}
  match parse_json_rpc_request(result_body) {
    Ok(_) => panic()
    Err(error) => assert_eq(error.code(), JSON_RPC_INVALID_REQUEST)
  }
  match parse_json_rpc_request(error_body) {
    Ok(_) => panic()
    Err(error) => assert_eq(error.code(), JSON_RPC_INVALID_REQUEST)
  }
}

///|
test "invalid request fields fail closed" {
  let bad_version =
    #|{"jsonrpc":"1.0","id":1,"method":"tools/list","params":{}}
  let missing_method =
    #|{"jsonrpc":"2.0","id":1,"params":{}}
  let bad_id =
    #|{"jsonrpc":"2.0","id":{},"method":"tools/list","params":{}}
  let bad_params =
    #|{"jsonrpc":"2.0","id":1,"method":"tools/list","params":"nope"}
  for body in [bad_version, missing_method, bad_id, bad_params] {
    match parse_json_rpc_request(body) {
      Ok(_) => panic()
      Err(error) => assert_eq(error.code(), JSON_RPC_INVALID_REQUEST)
    }
  }
}

///|
test "header lookup is case-insensitive and trims values" {
  let headers = HttpHeaders::new([
    ("mcp-protocol-version", " 2026-07-28 "),
    ("MCP-METHOD", "server/discover"),
  ])
  assert_eq(headers.get(MCP_PROTOCOL_VERSION_HEADER), Some("2026-07-28"))
  assert_eq(headers.get(MCP_METHOD_HEADER), Some("server/discover"))
  assert_eq(headers.get(MCP_NAME_HEADER), None)
}

///|
test "mcp-method header must be present and match the body" {
  let request = expect_mcp_request(
    (
      #|{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"search","_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}
    ),
  )
  let ok = HttpHeaders::new([
    (MCP_PROTOCOL_VERSION_HEADER, "2026-07-28"),
    (MCP_METHOD_HEADER, "tools/call"),
    (MCP_NAME_HEADER, "search"),
  ])
  assert_eq(request.validate_headers(ok), None)
  assert_eq(
    validate_method_header(ok, "prompts/get"),
    Some(HeaderValueMismatch(MCP_METHOD_HEADER, "prompts/get", "tools/call")),
  )
  assert_eq(
    validate_method_header(HttpHeaders::empty(), "tools/call"),
    Some(MissingHeader(MCP_METHOD_HEADER)),
  )
  assert_eq(
    validate_method_header(
      HttpHeaders::new([(MCP_METHOD_HEADER, "TOOLS/CALL")]),
      "tools/call",
    ),
    Some(HeaderValueMismatch(MCP_METHOD_HEADER, "tools/call", "TOOLS/CALL")),
  )
}

///|
test "protocol version header must be present and match body metadata" {
  let stale = HttpHeaders::new([(MCP_PROTOCOL_VERSION_HEADER, "2025-11-25")])
  assert_eq(
    validate_protocol_version_header(stale, MCP_PROTOCOL_VERSION),
    Some(
      HeaderValueMismatch(
        MCP_PROTOCOL_VERSION_HEADER,
        MCP_PROTOCOL_VERSION,
        "2025-11-25",
      ),
    ),
  )
  assert_eq(
    validate_protocol_version_header(HttpHeaders::empty(), MCP_PROTOCOL_VERSION),
    Some(MissingHeader(MCP_PROTOCOL_VERSION_HEADER)),
  )
}

///|
test "mcp-name is required only for targeted methods" {
  assert_eq(mcp_name_source("tools/call"), ParamName)
  assert_eq(mcp_name_source("prompts/get"), ParamName)
  assert_eq(mcp_name_source("resources/read"), ParamUri)
  assert_eq(mcp_name_source("server/discover"), NoName)
  assert_eq(
    validate_name_header(HttpHeaders::empty(), "tools/call", Some("search")),
    Some(MissingHeader(MCP_NAME_HEADER)),
  )
  assert_eq(
    validate_name_header(
      HttpHeaders::new([(MCP_NAME_HEADER, "other")]),
      "tools/call",
      Some("search"),
    ),
    Some(HeaderValueMismatch(MCP_NAME_HEADER, "search", "other")),
  )
  assert_eq(
    validate_name_header(
      HttpHeaders::new([(MCP_NAME_HEADER, "file://a")]),
      "resources/read",
      Some("file://a"),
    ),
    None,
  )
  assert_eq(
    validate_name_header(HttpHeaders::empty(), "tools/list", None),
    None,
  )
  assert_eq(
    validate_name_header(HttpHeaders::empty(), "tools/call", None),
    Some(MissingBodyValue(MCP_NAME_HEADER, "tools/call", ParamName)),
  )
}

///|
test "mcp request requires the 2026-07-28 metadata protocol version" {
  let valid = expect_mcp_request(
    (
      #|{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}
    ),
  )
  assert_eq(valid.protocol_version(), MCP_PROTOCOL_VERSION)
  let missing =
    #|{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}
  match parse_mcp_request(missing) {
    Ok(_) => panic()
    Err(error) => assert_eq(error.code(), JSON_RPC_INVALID_REQUEST)
  }
  let unsupported =
    #|{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2025-11-25"}}}
  match parse_mcp_request(unsupported) {
    Ok(_) => panic()
    Err(error) => assert_eq(error.code(), MCP_UNSUPPORTED_PROTOCOL_VERSION)
  }
}

///|
test "optional client info and client capabilities are accepted but not authoritative" {
  let request = expect_mcp_request(
    (
      #|{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"my-app","version":"1.0"},"io.modelcontextprotocol/clientCapabilities":{}}}}
    ),
  )
  match request.client_info() {
    Some(Object(info)) =>
      match info.get("name") {
        Some(String(name)) => assert_eq(name, "my-app")
        _ => panic()
      }
    _ => panic()
  }
  match request.client_capabilities() {
    Some(Object(_)) => ()
    _ => panic()
  }
  let legacy_key =
    #|{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/capabilities":{}}}}
  let legacy = expect_mcp_request(legacy_key)
  assert_eq(legacy.client_capabilities(), None)
  let malformed =
    #|{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":"nope"}}}
  match parse_mcp_request(malformed) {
    Ok(_) => panic()
    Err(error) => assert_eq(error.code(), JSON_RPC_INVALID_REQUEST)
  }
}

///|
test "unsupported body protocol version uses -32022 with supported versions" {
  let body =
    #|{"jsonrpc":"2.0","id":1,"method":"server/discover","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2025-11-25"}}}
  match parse_mcp_request(body) {
    Ok(_) => panic()
    Err(error) => {
      assert_eq(error.code(), MCP_UNSUPPORTED_PROTOCOL_VERSION)
      let text = error.to_json_string()
      assert_true(text.contains("2026-07-28"[:]))
      assert_true(text.contains("2025-11-25"[:]))
    }
  }
}

///|
test "unexpected Mcp-Name fails closed" {
  let body =
    #|{"jsonrpc":"2.0","id":1,"method":"server/discover","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}
  let headers = HttpHeaders::new([
    (MCP_PROTOCOL_VERSION_HEADER, MCP_PROTOCOL_VERSION),
    (MCP_METHOD_HEADER, "server/discover"),
    (MCP_NAME_HEADER, "unexpected"),
  ])
  match validate_mcp_http_request(body, headers) {
    Ok(_) => panic()
    Err(response) => assert_eq(response.error().code(), MCP_HEADER_MISMATCH)
  }
}

///|
test "server discovery dispatch returns current minimal response" {
  let body =
    #|{"jsonrpc":"2.0","id":"discover-1","method":"server/discover","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientCapabilities":{}}}}
  let headers = HttpHeaders::new([
    (MCP_PROTOCOL_VERSION_HEADER, MCP_PROTOCOL_VERSION),
    (MCP_METHOD_HEADER, "server/discover"),
  ])
  let response = dispatch_mcp_http_request(
    body, headers, "f4ah6o/blog.mbt", "0.1.0",
  )
  assert_eq(response.status(), 200)
  let text = response.body()
  assert_true(text.contains("discover-1"[:]))
  assert_true(text.contains("supportedVersions"[:]))
  assert_true(text.contains("2026-07-28"[:]))
  assert_true(text.contains("io.modelcontextprotocol/serverInfo"[:]))
  assert_true(text.contains("\"capabilities\":{}"[:]))
  assert_true(text.contains("\"resultType\":\"complete\""[:]))
  assert_true(text.contains("\"cacheScope\":\"public\""[:]))
  assert_true(text.contains("\"ttlMs\":3600000"[:]))
}

///|
test "unknown method returns HTTP 404 and JSON-RPC -32601" {
  let body =
    #|{"jsonrpc":"2.0","id":9,"method":"tools/list","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}
  let headers = HttpHeaders::new([
    (MCP_PROTOCOL_VERSION_HEADER, MCP_PROTOCOL_VERSION),
    (MCP_METHOD_HEADER, "tools/list"),
  ])
  let response = dispatch_mcp_http_request(body, headers, "server", "1")
  assert_eq(response.status(), 404)
  assert_true(response.body().contains("-32601"[:]))
}

///|
test "dispatch preserves header and protocol error status contracts" {
  let body =
    #|{"jsonrpc":"2.0","id":"header-1","method":"server/discover","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}
  let missing_protocol = dispatch_mcp_http_request(
    body,
    HttpHeaders::new([(MCP_METHOD_HEADER, "server/discover")]),
    "server",
    "1",
  )
  assert_eq(missing_protocol.status(), 400)
  assert_true(missing_protocol.body().contains("-32020"[:]))
  assert_true(missing_protocol.body().contains("header-1"[:]))

  let method_mismatch = dispatch_mcp_http_request(
    body,
    HttpHeaders::new([
      (MCP_PROTOCOL_VERSION_HEADER, MCP_PROTOCOL_VERSION),
      (MCP_METHOD_HEADER, "tools/list"),
    ]),
    "server",
    "1",
  )
  assert_eq(method_mismatch.status(), 400)
  assert_true(method_mismatch.body().contains("-32020"[:]))

  let stale_body =
    #|{"jsonrpc":"2.0","id":"version-1","method":"server/discover","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2025-11-25"}}}
  let unsupported_protocol = dispatch_mcp_http_request(
    stale_body,
    HttpHeaders::new([
      (MCP_PROTOCOL_VERSION_HEADER, "2025-11-25"),
      (MCP_METHOD_HEADER, "server/discover"),
    ]),
    "server",
    "1",
  )
  assert_eq(unsupported_protocol.status(), 400)
  assert_true(unsupported_protocol.body().contains("-32022"[:]))
  assert_true(unsupported_protocol.body().contains("version-1"[:]))
}

///|
test "malformed and invalid requests remain HTTP 400 with JSON-RPC errors" {
  let malformed = dispatch_mcp_http_request(
    "{",
    HttpHeaders::empty(),
    "server",
    "1",
  )
  assert_eq(malformed.status(), 400)
  assert_true(malformed.body().contains("-32700"[:]))
  let invalid_body =
    #|{"jsonrpc":"1.0","id":1,"method":"server/discover","params":{}}
  let invalid = dispatch_mcp_http_request(
    invalid_body,
    HttpHeaders::empty(),
    "server",
    "1",
  )
  assert_eq(invalid.status(), 400)
  assert_true(invalid.body().contains("-32600"[:]))
}

///|
test "client notification is rejected over modern Streamable HTTP" {
  let body =
    #|{"jsonrpc":"2.0","method":"server/discover","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}
  let headers = HttpHeaders::new([
    (MCP_PROTOCOL_VERSION_HEADER, MCP_PROTOCOL_VERSION),
    (MCP_METHOD_HEADER, "server/discover"),
  ])
  let response = dispatch_mcp_http_request(body, headers, "server", "1")
  assert_eq(response.status(), 400)
  assert_true(response.body().contains("-32600"[:]))
}

///|
test "Streamable HTTP Accept requires json and event-stream" {
  assert_eq(
    valid_streamable_http_accept("application/json, text/event-stream"),
    true,
  )
  assert_eq(valid_streamable_http_accept("application/json"), false)
  assert_eq(valid_streamable_http_accept("text/event-stream"), false)
}

///|
test "body target mirrors params.name or params.uri" {
  let call = expect_mcp_request(
    (
      #|{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"search","_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}
    ),
  )
  assert_eq(call.body_target(), Some("search"))
  let read = expect_mcp_request(
    (
      #|{"jsonrpc":"2.0","id":1,"method":"resources/read","params":{"uri":"file://a","_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}
    ),
  )
  assert_eq(read.body_target(), Some("file://a"))
}

///|
test "header mismatch becomes -32020 and echoes the request id" {
  let body =
    #|{"jsonrpc":"2.0","id":"req-1","method":"tools/call","params":{"name":"search","_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}
  let headers = HttpHeaders::new([
    (MCP_PROTOCOL_VERSION_HEADER, "2026-07-28"),
    (MCP_METHOD_HEADER, "prompts/get"),
    (MCP_NAME_HEADER, "search"),
  ])
  match validate_mcp_http_request(body, headers) {
    Ok(_) => panic()
    Err(response) => {
      assert_eq(response.error().code(), MCP_HEADER_MISMATCH)
      match response.id() {
        String(id) => assert_eq(id, "req-1")
        _ => panic()
      }
      let text = response.to_json_string()
      assert_true(text.contains("-32020"[:]))
      assert_true(text.contains("req-1"[:]))
    }
  }
}

///|
test "full pipeline accepts a well-formed stateless request" {
  let body =
    #|{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}
  let headers = HttpHeaders::new([
    (MCP_PROTOCOL_VERSION_HEADER, "2026-07-28"),
    (MCP_METHOD_HEADER, "tools/list"),
  ])
  match validate_mcp_http_request(body, headers) {
    Ok(request) => assert_eq(request.method_name(), "tools/list")
    Err(_) => panic()
  }
  match validate_mcp_http_request("{", HttpHeaders::empty()) {
    Ok(_) => panic()
    Err(response) => {
      assert_eq(response.error().code(), JSON_RPC_PARSE_ERROR)
      match response.id() {
        Null => ()
        _ => panic()
      }
    }
  }
}

///|
test "MCP HTTP preflight enforces POST JSON and modern Accept" {
  let accept = "application/json, text/event-stream"
  assert_eq(mcp_http_preflight_status("POST", "application/json", accept), 200)
  assert_eq(mcp_http_preflight_status("GET", "application/json", accept), 405)
  assert_eq(mcp_http_preflight_status("POST", "text/plain", accept), 415)
  assert_eq(
    mcp_http_preflight_status("POST", "application/json", "application/json"),
    406,
  )
}

///|
test "MCP auth failures map to HTTP bearer boundary" {
  assert_eq(
    mcp_auth_status(@oauth.ProtectedResourceAuthorization::MissingToken),
    401,
  )
  assert_eq(
    mcp_auth_status(@oauth.ProtectedResourceAuthorization::InvalidToken),
    401,
  )
  assert_eq(
    mcp_auth_status(@oauth.ProtectedResourceAuthorization::InsufficientScope),
    403,
  )
  assert_eq(
    mcp_auth_challenge_error(
      @oauth.ProtectedResourceAuthorization::MissingToken,
    ),
    None,
  )
  assert_eq(
    mcp_auth_challenge_error(
      @oauth.ProtectedResourceAuthorization::InvalidToken,
    ),
    Some("invalid_token"),
  )
  assert_eq(
    mcp_auth_challenge_error(
      @oauth.ProtectedResourceAuthorization::InsufficientScope,
    ),
    Some("insufficient_scope"),
  )
}

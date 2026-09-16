///|
test "supported OAuth scopes validate" {
  assert_eq(validate_scope("blog:read blog:write"), true)
  assert_eq(validate_scope("offline_access"), true)
  assert_eq(validate_scope("blog:admin"), false)
  assert_eq(validate_scope("blog:read blog:read"), false)
  assert_eq(validate_scope("blog:read  blog:write"), false)
}

///|
test "scope containment validates both sets" {
  assert_eq(scope_contains("blog:read blog:write", "blog:read"), true)
  assert_eq(scope_contains("blog:read", "blog:publish"), false)
}

///|
test "canonical URL rejects unsafe origins" {
  assert_eq(canonical_base_url("https://blog.example/"), Some("https://blog.example"))
  assert_eq(canonical_base_url("http://blog.example"), None)
  assert_eq(canonical_base_url("//blog.example"), None)
}

///|
test "metadata uses one configured issuer and resource" {
  let resource_metadata = protected_resource_metadata("https://blog.example/")
  assert_eq(resource_metadata.contains("https://blog.example/mcp"[:]), true)
  assert_eq(resource_metadata.contains("blog:read"[:]), true)
  let authorization = authorization_server_metadata("https://blog.example")
  assert_eq(authorization.contains("https://blog.example/oauth/authorize"[:]), true)
  assert_eq(authorization.contains("S256"[:]), true)
  assert_eq(authorization.contains("client_id_metadata_document_supported"[:]), true)
}

///|
test "PKCE verifier and challenge syntax" {
  assert_eq(validate_pkce_verifier("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"), true)
  assert_eq(validate_pkce_verifier("too short"), false)
  assert_eq(validate_pkce_challenge("E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"), true)
  assert_eq(validate_pkce_challenge("not-base64url"), false)
}

///|
async test "RFC 7636 S256 known vector" {
  let result = pkce_s256("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
  assert_eq(result, Some("E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"))
}

///|
async test "PKCE rejects invalid verifier before crypto" {
  assert_eq(pkce_s256("invalid verifier"), None)
}

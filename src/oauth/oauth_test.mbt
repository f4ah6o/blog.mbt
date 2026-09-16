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
  assert_eq(
    canonical_base_url("https://blog.example/"),
    Some("https://blog.example"),
  )
  assert_eq(canonical_base_url("http://blog.example"), None)
  assert_eq(canonical_base_url("//blog.example"), None)
}

///|
test "metadata uses one configured issuer and resource" {
  let resource_metadata = protected_resource_metadata("https://blog.example/")
  assert_eq(resource_metadata.contains("https://blog.example/mcp"[:]), true)
  assert_eq(resource_metadata.contains("blog:read"[:]), true)
  let authorization = authorization_server_metadata("https://blog.example")
  assert_eq(
    authorization.contains("https://blog.example/oauth/authorize"[:]),
    true,
  )
  assert_eq(authorization.contains("S256"[:]), true)
  assert_eq(
    authorization.contains("client_id_metadata_document_supported"[:]),
    true,
  )
}

///|
test "PKCE verifier and challenge syntax" {
  assert_eq(
    validate_pkce_verifier("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"),
    true,
  )
  assert_eq(validate_pkce_verifier("too short"), false)
  assert_eq(
    validate_pkce_challenge("E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"),
    true,
  )
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

///|
test "opaque secrets require at least 256-bit base64url syntax" {
  assert_eq(
    validate_opaque_secret("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"),
    true,
  )
  assert_eq(validate_opaque_secret("short"), false)
  assert_eq(
    validate_opaque_secret("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="),
    false,
  )
  assert_eq(
    validate_opaque_secret("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/"),
    false,
  )
}

///|
async test "opaque secret generation uses 256 bits" {
  let secret = generate_opaque_secret()
  assert_eq(secret.length(), 43)
  assert_eq(validate_opaque_secret(secret), true)
}

///|
async test "SHA-256 has a deterministic hex test vector" {
  assert_eq(
    sha256_hex("abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  )
  assert_eq(
    validate_sha256_hex(
      "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
    ),
    true,
  )
  assert_eq(validate_sha256_hex("ABC"), false)
}

///|
async test "PKCE S256 verification matches the RFC vector" {
  assert_eq(
    verify_pkce_s256(
      "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM", "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk",
    ),
    true,
  )
  assert_eq(
    verify_pkce_s256(
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk",
    ),
    false,
  )
}

///|
test "OAuth record constructors reject invalid state" {
  let hash = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
  let challenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
  assert_eq(
    authorization_code_record(
      hash, "client", "https://client.example/callback", "https://blog.example/mcp",
      "blog:read", challenge, "plain", 100, 200,
    )
    is None,
    true,
  )
  assert_eq(
    access_token_record(
      hash, "client", "https://blog.example/mcp", "blog:admin", 100, 200,
    )
    is None,
    true,
  )
  assert_eq(
    refresh_token_record(
      hash, hash, "client", "https://blog.example/mcp", "blog:read", 200, 100,
    )
    is None,
    true,
  )
}

///|
test "bearer parser fails closed" {
  let valid = "Bearer AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  let parsed = parse_bearer_header(valid)
  assert_eq(
    match parsed {
      Some(value) => value.token
      None => ""
    },
    valid[7:].to_owned(),
  )
  let lowercase = parse_bearer_header(
    "bearer AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
  )
  assert_eq(
    match lowercase {
      Some(value) => value.token
      None => ""
    },
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
  )
  let multi_space = parse_bearer_header(
    "Bearer  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
  )
  assert_eq(
    match multi_space {
      Some(value) => value.token
      None => ""
    },
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
  )
  assert_eq(parse_bearer_header("Bearer "), None)
  assert_eq(
    parse_bearer_header(
      "Bearer AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA, Bearer BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
    ),
    None,
  )
  assert_eq(
    parse_bearer_header("Bearer\tAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"),
    None,
  )
}

///|
test "expiry and scope enforcement fail closed" {
  assert_eq(is_unexpired(101, 100), true)
  assert_eq(is_unexpired(100, 100), false)
  assert_eq(scope_contains("blog:read blog:write", "blog:read"), true)
  assert_eq(scope_contains("blog:read", "blog:write"), false)
  assert_eq(scope_contains("blog:read blog:read", "blog:read"), false)
}

///|
test "authorization code and refresh decisions enforce one-time state" {
  assert_eq(redeem_is_allowed(true, None, 101, 100), true)
  assert_eq(redeem_is_allowed(true, Some(100), 101, 100), false)
  assert_eq(redeem_is_allowed(true, None, 100, 100), false)
  assert_eq(
    refresh_rotation_decision(true, None, None, 101, 100),
    RefreshRotated,
  )
  assert_eq(
    refresh_rotation_decision(true, Some(100), None, 101, 100),
    RefreshReplay,
  )
  assert_eq(
    refresh_rotation_decision(false, None, None, 101, 100),
    RefreshInvalid,
  )
}

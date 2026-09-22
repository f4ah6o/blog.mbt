///|
test "supported OAuth scopes validate" {
  assert_eq(validate_scope("mcp:discover"), true)
  assert_eq(validate_scope("blog:read blog:write"), true)
  assert_eq(validate_scope("offline_access"), true)
  assert_eq(validate_scope("blog:admin"), false)
  assert_eq(validate_scope("blog:read blog:read"), false)
  assert_eq(validate_scope("blog:read  blog:write"), false)
}

///|
test "scope containment validates both sets" {
  assert_eq(scope_contains("mcp:discover blog:read", "mcp:discover"), true)
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
  assert_eq(
    authorization.contains("authorization_response_iss_parameter_supported"[:]),
    true,
  )
  assert_eq(resource_metadata.contains("offline_access"[:]), false)
}

///|
test "protected resource scopes exclude offline access" {
  assert_eq(validate_protected_resource_scope("mcp:discover"), true)
  assert_eq(validate_protected_resource_scope("blog:read"), true)
  assert_eq(validate_protected_resource_scope("blog:read blog:write"), true)
  assert_eq(validate_protected_resource_scope("offline_access"), false)
  assert_eq(
    validate_protected_resource_scope("blog:read offline_access"),
    false,
  )
}

///|
test "protected resource record validation binds resource expiry and scope" {
  let hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  let token = access_token_record(
    hash, "client", "https://blog.example/mcp", "mcp:discover", 100, 200,
  ).unwrap()
  assert_eq(
    protected_resource_record_decision(
      Some(token),
      "https://blog.example/mcp",
      "mcp:discover",
      150,
    )
    is Authorized(_),
    true,
  )
  assert_eq(
    protected_resource_record_decision(
      Some(token),
      "https://other.example/mcp",
      "mcp:discover",
      150,
    ),
    InvalidToken,
  )
  assert_eq(
    protected_resource_record_decision(
      Some(token),
      "https://blog.example/mcp",
      "mcp:discover",
      200,
    ),
    InvalidToken,
  )
  let content_token = access_token_record(
    hash, "client", "https://blog.example/mcp", "blog:read", 100, 200,
  ).unwrap()
  assert_eq(
    protected_resource_record_decision(
      Some(content_token),
      "https://blog.example/mcp",
      "mcp:discover",
      150,
    ),
    InsufficientScope,
  )
}

///|
test "protected resource decisions distinguish invalid and insufficient tokens" {
  let hash = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
  let token = access_token_record(
    hash, "client", "https://blog.example/mcp", "blog:read", 100, 200,
  ).unwrap()
  assert_eq(protected_resource_decision(None, "blog:read"), InvalidToken)
  assert_eq(
    protected_resource_decision(Some(token), "blog:write"),
    InsufficientScope,
  )
  assert_eq(
    protected_resource_decision(Some(token), "blog:read") is Authorized(_),
    true,
  )
  assert_eq(
    protected_resource_decision(Some(token), "offline_access"),
    InvalidConfiguration,
  )
}

///|
test "protected resource challenges carry exact metadata and scope" {
  let missing = protected_resource_challenge(
    "https://blog.example/",
    "blog:read",
    None,
  ).unwrap()
  assert_eq(
    missing, "Bearer resource_metadata=\"https://blog.example/.well-known/oauth-protected-resource\", scope=\"blog:read\"",
  )
  let invalid = protected_resource_challenge(
    "https://blog.example",
    "blog:write",
    Some("invalid_token"),
  ).unwrap()
  assert_eq(invalid.contains("error=\"invalid_token\""[:]), true)
  assert_eq(invalid.contains("scope=\"blog:write\""[:]), true)
  let insufficient = protected_resource_challenge(
    "https://blog.example",
    "blog:publish",
    Some("insufficient_scope"),
  ).unwrap()
  assert_eq(insufficient.contains("error=\"insufficient_scope\""[:]), true)
  assert_eq(
    protected_resource_challenge("https://blog.example", "offline_access", None),
    None,
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
fn test_client_metadata() -> ClientMetadata {
  parse_client_metadata(
    "https://client.example/client.json", "{\"client_id\":\"https://client.example/client.json\",\"client_name\":\"Example\",\"redirect_uris\":[\"https://client.example/callback\"]}",
  ).unwrap()
}

///|
test "CIMD identifiers require absolute HTTPS URLs" {
  assert_eq(validate_client_id_url("https://client.example/client.json"), true)
  assert_eq(validate_client_id_url("https://client.example"), false)
  assert_eq(
    validate_client_id_url("https://user@client.example/client.json"),
    false,
  )
  assert_eq(
    validate_client_id_url("https://client.example/a/../client.json"),
    false,
  )
  assert_eq(
    validate_client_id_url("https://client.example/client.json?q=1"),
    false,
  )
  assert_eq(validate_client_id_url("http://client.example/client.json"), false)
  assert_eq(
    validate_client_id_url("https://client.example/client.json#frag"),
    false,
  )
  assert_eq(validate_client_id_url("https://client.example/a b"), false)
}

///|
test "CIMD metadata binds exact client id and declared HTTPS redirects" {
  let client_id = "https://client.example/client.json"
  let raw = "{\"client_id\":\"https://client.example/client.json\",\"client_name\":\"Example\",\"redirect_uris\":[\"https://client.example/callback\"]}"
  assert_eq(parse_client_metadata(client_id, raw) is Some(_), true)
  assert_eq(
    parse_client_metadata(
      client_id, "{\"client_id\":\"https://evil.example/client.json\",\"redirect_uris\":[\"https://client.example/callback\"]}",
    )
    is None,
    true,
  )
  assert_eq(
    parse_client_metadata(
      client_id, "{\"redirect_uris\":[\"https://client.example/callback\"]}",
    )
    is None,
    true,
  )
  assert_eq(
    parse_client_metadata(
      client_id, "{\"client_id\":\"https://client.example/client.json\",\"redirect_uris\":[\"https://client.example/callback\"]}",
    )
    is None,
    true,
  )
  assert_eq(
    parse_client_metadata(
      client_id, "{\"client_id\":\"https://client.example/client.json\",\"redirect_uris\":[]}",
    )
    is None,
    true,
  )
  assert_eq(
    parse_client_metadata(
      client_id, "{\"client_id\":\"https://client.example/client.json\",\"redirect_uris\":[\"http://client.example/callback\"]}",
    )
    is None,
    true,
  )
  assert_eq(
    parse_client_metadata("http://client.example/client.json", raw) is None,
    true,
  )
  assert_eq(parse_client_metadata(client_id, "not json") is None, true)
  match parse_client_metadata(client_id, raw) {
    Some(metadata) => {
      assert_eq(
        metadata.redirect_uri_allowed("https://client.example/callback"),
        true,
      )
      assert_eq(
        metadata.redirect_uri_allowed("https://client.example/other"),
        false,
      )
    }
    None => fail("expected valid metadata")
  }
}

///|
test "authorization requests bind CIMD client, redirect, resource, and S256" {
  let client = test_client_metadata()
  let client_id = "https://client.example/client.json"
  let redirect_uri = "https://client.example/callback"
  let resource = "https://blog.example/mcp"
  let challenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
  let valid = validate_authorization_request(
    "code",
    client_id,
    redirect_uri,
    resource,
    "blog:read",
    challenge,
    "S256",
    Some("opaque-state"),
    resource,
    client,
  )
  assert_eq(valid is Some(_), true)
  assert_eq(
    validate_authorization_request(
      "token",
      client_id,
      redirect_uri,
      resource,
      "blog:read",
      challenge,
      "S256",
      None,
      resource,
      client,
    )
    is None,
    true,
  )
  assert_eq(
    validate_authorization_request(
      "code",
      client_id,
      "https://client.example/other",
      resource,
      "blog:read",
      challenge,
      "S256",
      None,
      resource,
      client,
    )
    is None,
    true,
  )
  assert_eq(
    validate_authorization_request(
      "code",
      client_id,
      redirect_uri,
      "https://blog.example/other",
      "blog:read",
      challenge,
      "S256",
      None,
      resource,
      client,
    )
    is None,
    true,
  )
  assert_eq(
    validate_authorization_request(
      "code",
      client_id,
      redirect_uri,
      resource,
      "blog:read",
      challenge,
      "plain",
      None,
      resource,
      client,
    )
    is None,
    true,
  )
  assert_eq(
    valid_redirect_uri("https://client.example/callback#fragment"),
    false,
  )
}

///|
test "pending authorizations bind challenge, user, request, and expiry" {
  let client = test_client_metadata()
  let client_id = "https://client.example/client.json"
  let redirect_uri = "https://client.example/callback"
  let resource = "https://blog.example/mcp"
  let challenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
  let request = validate_authorization_request(
    "code",
    client_id,
    redirect_uri,
    resource,
    "blog:read blog:write",
    challenge,
    "S256",
    Some("opaque-state"),
    resource,
    client,
  ).unwrap()
  let pending = pending_authorization(
    "challenge-id",
    "oauth-user",
    request,
    100,
    PENDING_AUTHORIZATION_TTL_SECONDS,
  ).unwrap()
  assert_eq(pending.challenge_identifier(), "challenge-id")
  assert_eq(pending.expiry(), 100 + PENDING_AUTHORIZATION_TTL_SECONDS)
  assert_eq(
    pending.bound_request().code_redirect("opaque-code"),
    request.code_redirect("opaque-code"),
  )
  assert_eq(
    pending_authorization(
      "",
      "oauth-user",
      request,
      100,
      PENDING_AUTHORIZATION_TTL_SECONDS,
    )
    is None,
    true,
  )
  assert_eq(
    pending_authorization(
      "challenge-id",
      "",
      request,
      100,
      PENDING_AUTHORIZATION_TTL_SECONDS,
    )
    is None,
    true,
  )
  let zero_lifetime = pending_authorization(
    "challenge-id", "oauth-user", request, 100, 0,
  )
  assert_eq(zero_lifetime is None, true)
}

///|
test "pending claim decision enforces one-time expiry" {
  assert_eq(pending_claim_is_allowed(true, None, 101, 100), true)
  assert_eq(pending_claim_is_allowed(true, Some(100), 101, 100), false)
  assert_eq(pending_claim_is_allowed(true, None, 100, 100), false)
  assert_eq(pending_claim_is_allowed(false, None, 101, 100), false)
}

///|
test "authorization redirects preserve state and existing query" {
  let result = authorization_redirect(
    "https://client.example/callback?existing=1",
    "code",
    "opaque-code",
    Some("state with space"),
  )
  assert_eq(result.contains("existing=1"[:]), true)
  assert_eq(result.contains("code=opaque-code"[:]), true)
  assert_eq(result.contains("state=state+with+space"[:]), true)
}

///|
test "successful authorization redirects include the RFC 9207 issuer" {
  let result = authorization_redirect_with_issuer(
    "https://client.example/callback",
    "code",
    "opaque-code",
    Some("opaque-state"),
    "https://blog.example",
  )
  assert_eq(result.contains("code=opaque-code"[:]), true)
  assert_eq(result.contains("state=opaque-state"[:]), true)
  assert_eq(result.contains("iss=https%3A%2F%2Fblog.example"[:]), true)
  let error_result = authorization_redirect_with_issuer(
    "https://client.example/callback",
    "error",
    "invalid_request",
    Some("opaque-state"),
    "https://blog.example",
  )
  assert_eq(error_result.contains("error=invalid_request"[:]), true)
  assert_eq(error_result.contains("iss=https%3A%2F%2Fblog.example"[:]), true)
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

///|
test "token form rejects malformed and duplicate security fields" {
  assert_eq(
    parse_oauth_token_form("grant_type=authorization_code&code=a&code=b")
    is None,
    true,
  )
  assert_eq(
    parse_oauth_token_form("grant_type=authorization_code&code=%") is None,
    true,
  )
  assert_eq(
    parse_oauth_token_form("grant_type=authorization_code&unknown=value")
    is None,
    true,
  )
}

///|
test "token grant validation distinguishes supported grant requirements" {
  let code = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
  let auth = parse_oauth_token_form(
    "grant_type=authorization_code&code=" +
    code +
    "&client_id=https%3A%2F%2Fclient.example%2Fclient.json&redirect_uri=https%3A%2F%2Fclient.example%2Fcallback&resource=https%3A%2F%2Fblog.example%2Fmcp&code_verifier=" +
    verifier,
  ).unwrap()
  assert_eq(validate_oauth_token_request(auth), Some(AuthorizationCode))
  let refresh = parse_oauth_token_form(
    "grant_type=refresh_token&refresh_token=" +
    code +
    "&client_id=client&resource=https%3A%2F%2Fblog.example%2Fmcp",
  ).unwrap()
  assert_eq(validate_oauth_token_request(refresh), Some(RefreshToken))
  let unsupported = parse_oauth_token_form("grant_type=client_credentials").unwrap()
  assert_eq(validate_oauth_token_request(unsupported), None)
}

///|
test "dynamic client registration validates redirect and grant metadata" {
  let valid = parse_client_registration(
    "{\"redirect_uris\":[\"https://client.example/callback\"],\"client_name\":\"ChatGPT\"}",
  ).unwrap()
  assert_eq(valid.client_name, "ChatGPT")
  assert_eq(valid.token_endpoint_auth_method, "none")
  assert_eq(valid.requires_secret(), false)
  assert_eq(valid.grant_types, ["authorization_code", "refresh_token"])
  assert_eq(
    parse_client_registration(
      "{\"redirect_uris\":[\"https://client.example/callback\"],\"token_endpoint_auth_method\":\"client_secret_basic\"}",
    )
    .unwrap()
    .requires_secret(),
    true,
  )
  assert_eq(
    parse_client_registration(
      "{\"redirect_uris\":[\"https://client.example/callback\"],\"token_endpoint_auth_method\":\"private_key_jwt\"}",
    )
    is None,
    true,
  )
  assert_eq(parse_client_registration("{\"redirect_uris\":[]}") is None, true)
  assert_eq(parse_client_registration("{\"client_name\":\"x\"}") is None, true)
  assert_eq(
    parse_client_registration(
      "{\"redirect_uris\":[\"http://client.example/callback\"]}",
    )
    is None,
    true,
  )
  assert_eq(
    parse_client_registration(
      "{\"redirect_uris\":[\"https://client.example/callback#frag\"]}",
    )
    is None,
    true,
  )
  assert_eq(
    parse_client_registration(
      "{\"redirect_uris\":[\"https://client.example/callback\"],\"grant_types\":[\"client_credentials\"]}",
    )
    is None,
    true,
  )
  assert_eq(
    parse_client_registration(
      "{\"redirect_uris\":[\"https://client.example/callback\"],\"grant_types\":[\"refresh_token\"]}",
    )
    is None,
    true,
  )
  assert_eq(
    parse_client_registration(
      "{\"redirect_uris\":[\"https://client.example/callback\"],\"response_types\":[\"token\"]}",
    )
    is None,
    true,
  )
  assert_eq(
    parse_client_registration(
      "{\"redirect_uris\":[\"https://client.example/callback\"],\"scope\":\"blog:admin\"}",
    )
    is None,
    true,
  )
  assert_eq(
    parse_client_registration(
      "{\"redirect_uris\":[\"https://client.example/callback\"],\"scope\":\"mcp:discover blog:read\"}",
    ).unwrap().scope,
    "mcp:discover blog:read",
  )
  assert_eq(parse_client_registration("not json") is None, true)
  assert_eq(parse_client_registration("") is None, true)
}

///|
test "registration responses bind issued client material" {
  let registration = parse_client_registration(
    "{\"redirect_uris\":[\"https://client.example/callback\"],\"client_name\":\"ChatGPT\",\"token_endpoint_auth_method\":\"client_secret_post\",\"scope\":\"blog:read\"}",
  ).unwrap()
  let record = registration.record("dcr-abc", Some("hash"), 100)
  assert_eq(record.client_id, "dcr-abc")
  assert_eq(record.client_name, "ChatGPT")
  assert_eq(record.client_secret_hash, Some("hash"))
  assert_eq(record.scope, "blog:read")
  let body = registration.response_json("dcr-abc", Some("secret"), 100)
  let parsed = @json.parse(body) catch { _ => fail("expected valid json") }
  match parsed {
    Object(map) => {
      assert_eq(map["client_id"], "dcr-abc".to_json())
      assert_eq(map["client_secret"], "secret".to_json())
      assert_eq(
        map["token_endpoint_auth_method"],
        "client_secret_post".to_json(),
      )
      assert_eq(map["scope"], "blog:read".to_json())
    }
    _ => fail("expected response object")
  }
  assert_eq(registration.record("dcr-abc", None, 100).client_secret_hash, None)
  let public = parse_client_registration(
    "{\"redirect_uris\":[\"https://client.example/callback\"]}",
  ).unwrap()
  let public_parsed = @json.parse(public.response_json("dcr-def", None, 100)) catch {
    _ => fail("expected valid json")
  }
  match public_parsed {
    Object(map) => {
      assert_eq(map.contains("client_secret"), false)
      assert_eq(map["client_name"], "dcr-def".to_json())
    }
    _ => fail("expected response object")
  }
}

///|
test "registered client metadata rebuilds the authorize-time shape" {
  assert_eq(
    registered_client_metadata("dcr-abc", "ChatGPT", [
      "https://client.example/callback",
    ])
    is Some(_),
    true,
  )
  assert_eq(
    registered_client_metadata("", "ChatGPT", [
      "https://client.example/callback",
    ])
    is None,
    true,
  )
  assert_eq(registered_client_metadata("dcr-abc", "ChatGPT", []) is None, true)
  assert_eq(
    registered_client_metadata("dcr-abc", "ChatGPT", [
      "http://client.example/callback",
    ])
    is None,
    true,
  )
  match
    registered_client_metadata("dcr-abc", "ChatGPT", [
      "https://client.example/callback",
    ]) {
    Some(client) => {
      assert_eq(
        client.redirect_uri_allowed("https://client.example/callback"),
        true,
      )
      assert_eq(
        client.redirect_uri_allowed("https://client.example/other"),
        false,
      )
    }
    None => fail("expected registered metadata")
  }
}

///|
test "stored client metadata parses and revalidates persisted JSON" {
  let stored = StoredOAuthClient::{
    client_name: "ChatGPT",
    redirect_uris: "[\"https://client.example/callback\"]",
    client_secret_hash: None,
    scope: "blog:read",
  }
  assert_eq(stored_client_metadata("dcr-abc", stored) is Some(_), true)
  let malformed = StoredOAuthClient::{
    client_name: "ChatGPT",
    redirect_uris: "not json",
    client_secret_hash: None,
    scope: "",
  }
  assert_eq(stored_client_metadata("dcr-abc", malformed) is None, true)
  let unsafe_uri = StoredOAuthClient::{
    client_name: "ChatGPT",
    redirect_uris: "[\"http://client.example/callback\"]",
    client_secret_hash: None,
    scope: "",
  }
  assert_eq(stored_client_metadata("dcr-abc", unsafe_uri) is None, true)
}

///|
test "scope subset bounds registered client grants" {
  assert_eq(scope_subset("blog:read", ""), true)
  assert_eq(scope_subset("blog:read", "blog:read blog:write"), true)
  assert_eq(scope_subset("blog:read blog:publish", "blog:read"), false)
  assert_eq(scope_subset("blog:read", "blog:write"), false)
}

///|
test "token form accepts an optional client_secret field" {
  let code = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
  let auth = parse_oauth_token_form(
    "grant_type=authorization_code&code=" +
    code +
    "&client_id=dcr-abc&redirect_uri=https%3A%2F%2Fclient.example%2Fcallback&resource=https%3A%2F%2Fblog.example%2Fmcp&code_verifier=" +
    verifier +
    "&client_secret=secret",
  ).unwrap()
  assert_eq(validate_oauth_token_request(auth), Some(AuthorizationCode))
  assert_eq(auth.client_secret(), Some("secret"))
  assert_eq(
    parse_oauth_token_form(
      "grant_type=refresh_token&refresh_token=" +
      code +
      "&client_id=dcr-abc&resource=https%3A%2F%2Fblog.example%2Fmcp&client_secret=a&client_secret=b",
    )
    is None,
    true,
  )
}

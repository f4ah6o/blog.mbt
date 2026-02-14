///|
fn parse_int(value : String) -> Int? {
  let parsed : Result[Int, @strconv.StrConvError] = try? @strconv.parse_int(
    value,
  )
  match parsed {
    Ok(v) => Some(v)
    Err(_) => None
  }
}

///|
fn parse_id(segment : String) -> Int? {
  match parse_int(segment) {
    Some(v) if v > 0 => Some(v)
    _ => None
  }
}

///|
fn path_segments(path : String) -> Array[String] {
  let mut start = 0
  let mut end = path.length()
  if path.has_prefix("/") {
    start = 1
  }
  if end > start && path.has_suffix("/") {
    end = end - 1
  }
  let trimmed = if start == 0 && end == path.length() {
    path
  } else {
    let view = try! path[start:end]
    view.to_string()
  }
  if trimmed == "" {
    return []
  }
  let segments : Array[String] = []
  for part in trimmed.split("/") {
    segments.push(part.to_string())
  }
  segments
}

///|
fn validate_post_form(title : String, slug : String) -> Array[String] {
  let errors : Array[String] = []
  if title.trim().length() == 0 {
    errors.push("Title is required.")
  }
  if slug.trim().length() == 0 {
    errors.push("Slug is required.")
  }
  errors
}

///|
async fn read_form(req : @http.Request) -> Map[String, String] {
  let body = req.text()
  parse_urlencoded(body)
}

///|
/// Read JSON body from request
async fn read_json_body(req : @http.Request) -> String {
  req.text()
}

// =============================================================================
// Auth Routes (Public - no JWT required)
// =============================================================================

///|
/// Handle GET /admin/login
fn handle_login_page() -> @http.Response {
  html_response(render_login_page(None), 200)
}

///|
/// Handle GET /admin/register
fn handle_register_page() -> @http.Response {
  html_response(render_register_page(None), 200)
}

///|
/// Handle GET /admin/login/options - Get WebAuthn authentication options
async fn handle_login_options(
  kv : @core.Any,
  env : @cloudflare.CloudflareEnv,
) -> @http.Response {
  // Get required config
  let user_id = match get_admin_user_id(env) {
    Some(id) => id
    None =>
      return json_response("{\"error\":\"ADMIN_USER_ID not configured\"}", 500)
  }
  let rp_id = match get_rp_id(env) {
    Some(id) => id
    None => return json_response("{\"error\":\"RP_ID not configured\"}", 500)
  }
  //
  // Generate authentication options
  let options = generate_auth_options(kv, user_id, rp_id)
  //
  // Return as JSON
  let json_str = options.to_json().stringify()
  json_response(json_str, 200)
}

///|
/// Handle POST /admin/login/verify - Verify WebAuthn authentication
async fn handle_login_verify(
  kv : @core.Any,
  env : @cloudflare.CloudflareEnv,
  req : @http.Request,
) -> @http.Response {
  // Get required config
  let user_id = match get_admin_user_id(env) {
    Some(id) => id
    None =>
      return json_response("{\"error\":\"ADMIN_USER_ID not configured\"}", 500)
  }
  let rp_id = match get_rp_id(env) {
    Some(id) => id
    None => return json_response("{\"error\":\"RP_ID not configured\"}", 500)
  }
  let origin = match get_rp_origin(env) {
    Some(o) => o
    None =>
      return json_response("{\"error\":\"RP_ORIGIN not configured\"}", 500)
  }
  let jwt_secret = match get_jwt_secret(env) {
    Some(s) => s
    None =>
      return json_response("{\"error\":\"JWT_SECRET not configured\"}", 500)
  }
  let jwt_expires_in = get_jwt_expires_in(env)
  //
  // Parse request body
  let body = read_json_body(req)
  let json_result = try? @json.parse(body)
  let json = match json_result {
    Ok(j) => j
    Err(_) => return json_response("{\"error\":\"Invalid JSON\"}", 400)
  }
  let request_result : Result[AuthVerifyRequest, _] = try? @json.from_json(json)
  let request = match request_result {
    Ok(r) => r
    Err(_) => return json_response("{\"error\":\"Invalid request body\"}", 400)
  }
  //
  // Verify authentication
  let result = verify_authentication(kv, user_id, rp_id, origin, request)
  match result {
    AuthVerifyResult::Success(_counter) => {
      // Create JWT session token
      let jwt = create_session_token(user_id, jwt_secret, jwt_expires_in)
      // Return success with session cookie
      let secure_cookie = should_use_secure_cookie(env)
      json_response_with_session_cookie(
        "{\"success\":true}", 200, jwt, jwt_expires_in, secure_cookie,
      )
    }
    AuthVerifyResult::ChallengeInvalid =>
      json_response("{\"error\":\"Challenge invalid or expired\"}", 401)
    AuthVerifyResult::CredentialNotFound =>
      json_response("{\"error\":\"Credential not found\"}", 401)
    AuthVerifyResult::VerificationFailed(msg) =>
      json_response("{\"error\":\"Verification failed: " + msg + "\"}", 401)
  }
}

///|
/// Handle GET /admin/register/options - Get WebAuthn registration options
async fn handle_register_options(
  kv : @core.Any,
  env : @cloudflare.CloudflareEnv,
) -> @http.Response {
  // Get required config
  let user_id = match get_admin_user_id(env) {
    Some(id) => id
    None =>
      return json_response("{\"error\":\"ADMIN_USER_ID not configured\"}", 500)
  }
  let rp_id = match get_rp_id(env) {
    Some(id) => id
    None => return json_response("{\"error\":\"RP_ID not configured\"}", 500)
  }
  let rp_name = match get_rp_name(env) {
    Some(n) => n
    None => return json_response("{\"error\":\"RP_NAME not configured\"}", 500)
  }
  //
  // Generate registration options (use user_id as display name too)
  let options = generate_reg_options(kv, user_id, user_id, rp_id, rp_name)
  //
  // Return as JSON
  let json_str = options.to_json().stringify()
  json_response(json_str, 200)
}

///|
/// Handle POST /admin/register/verify - Verify WebAuthn registration
async fn handle_register_verify(
  kv : @core.Any,
  env : @cloudflare.CloudflareEnv,
  req : @http.Request,
) -> @http.Response {
  // Get required config
  let user_id = match get_admin_user_id(env) {
    Some(id) => id
    None =>
      return json_response("{\"error\":\"ADMIN_USER_ID not configured\"}", 500)
  }
  let rp_id = match get_rp_id(env) {
    Some(id) => id
    None => return json_response("{\"error\":\"RP_ID not configured\"}", 500)
  }
  let origin = match get_rp_origin(env) {
    Some(o) => o
    None =>
      return json_response("{\"error\":\"RP_ORIGIN not configured\"}", 500)
  }
  //
  // Parse request body
  let body = read_json_body(req)
  let json_result = try? @json.parse(body)
  let json = match json_result {
    Ok(j) => j
    Err(_) => return json_response("{\"error\":\"Invalid JSON\"}", 400)
  }
  let request_result : Result[RegVerifyRequest, _] = try? @json.from_json(json)
  let request = match request_result {
    Ok(r) => r
    Err(e) =>
      return json_response(
        "{\"error\":\"Invalid request body: " +
        e.to_string() +
        "\", \"received\": " +
        body +
        "}",
        400,
      )
  }
  //
  // Verify registration
  let result = verify_registration(kv, user_id, rp_id, origin, request)
  match result {
    RegVerifyResult::Success => json_response("{\"success\":true}", 200)
    RegVerifyResult::ChallengeInvalid =>
      json_response("{\"error\":\"Challenge invalid or expired\"}", 401)
    RegVerifyResult::VerificationFailed(msg) =>
      json_response("{\"error\":\"Verification failed: " + msg + "\"}", 401)
  }
}

///|
/// Handle POST /admin/logout
fn handle_logout(env : @cloudflare.CloudflareEnv) -> @http.Response {
  let secure_cookie = should_use_secure_cookie(env)
  redirect_with_logout_cookie("/admin/login", secure_cookie)
}

// =============================================================================
// Protected Routes (JWT required)
// =============================================================================

///|
async fn handle_protected_get(
  db : @core.Any,
  segments : Array[String],
) -> @http.Response {
  if segments.length() == 1 && segments[0] == "admin" {
    let posts = list_posts(db, 200, 0) catch {
      _ =>
        return html_response(
          render_error_page("Database Error", "Failed to list posts."),
          500,
        )
    }
    return html_response(render_post_list(posts), 200)
  }
  if segments.length() == 2 && segments[0] == "admin" && segments[1] == "posts" {
    let posts = list_posts(db, 200, 0) catch {
      _ =>
        return html_response(
          render_error_page("Database Error", "Failed to list posts."),
          500,
        )
    }
    return html_response(render_post_list(posts), 200)
  }
  if segments.length() == 3 &&
    segments[0] == "admin" &&
    segments[1] == "posts" &&
    segments[2] == "new" {
    return html_response(render_post_new("", "", "", "", false, []), 200)
  }
  if segments.length() == 4 &&
    segments[0] == "admin" &&
    segments[1] == "posts" &&
    segments[3] == "edit" {
    return match parse_id(segments[2]) {
      Some(id) => {
        let post_opt : AdminPost? = get_post_by_id(db, id) catch {
          _ =>
            return html_response(
              render_error_page("Database Error", "Failed to load post."),
              500,
            )
        }
        match post_opt {
          Some(post) => html_response(render_post_edit(post, []), 200)
          None => not_found_response()
        }
      }
      None => not_found_response()
    }
  }
  if segments.length() == 3 &&
    segments[0] == "admin" &&
    segments[1] == "preview" {
    return match parse_id(segments[2]) {
      Some(id) => {
        let post_opt : AdminPost? = get_post_by_id(db, id) catch {
          _ =>
            return html_response(
              render_error_page("Database Error", "Failed to load post."),
              500,
            )
        }
        match post_opt {
          Some(post) => html_response(render_preview(post), 200)
          None => not_found_response()
        }
      }
      None => not_found_response()
    }
  }
  not_found_response()
}

///|
async fn handle_protected_post(
  db : @core.Any,
  req : @http.Request,
  segments : Array[String],
) -> @http.Response {
  if segments.length() == 2 && segments[0] == "admin" && segments[1] == "posts" {
    let form = read_form(req)
    let title = form_value(form, "title")
    let slug = form_value(form, "slug")
    let excerpt = form_value(form, "excerpt")
    let content = form_value(form, "content")
    let slide_flag = form_checked(form, "slide_flag")
    let errors = validate_post_form(title, slug)
    match @lib.validate_slide_markdown(content) {
      Some(msg) if slide_flag => errors.push(msg)
      _ => ()
    }
    if errors.length() > 0 {
      return html_response(
        render_post_new(title, slug, excerpt, content, slide_flag, errors),
        400,
      )
    }
    let now = now_iso()
    let new_id = insert_post(db, title, slug, excerpt, content, slide_flag, now) catch {
      _ =>
        return html_response(
          render_error_page("Database Error", "Failed to create post."),
          500,
        )
    }
    if new_id == 0 {
      return html_response(
        render_error_page("Database Error", "Failed to create post."),
        500,
      )
    }
    return redirect_to("/admin/posts/" + new_id.to_string() + "/edit")
  }
  if segments.length() == 3 && segments[0] == "admin" && segments[1] == "posts" {
    return match parse_id(segments[2]) {
      Some(id) => {
        let form = read_form(req)
        let title = form_value(form, "title")
        let slug = form_value(form, "slug")
        let excerpt = form_value(form, "excerpt")
        let content = form_value(form, "content")
        let slide_flag = form_checked(form, "slide_flag")
        let errors = validate_post_form(title, slug)
        match @lib.validate_slide_markdown(content) {
          Some(msg) if slide_flag => errors.push(msg)
          _ => ()
        }
        if errors.length() > 0 {
          let post_opt : AdminPost? = get_post_by_id(db, id) catch {
            _ =>
              return html_response(
                render_error_page("Database Error", "Failed to load post."),
                500,
              )
          }
          match post_opt {
            Some(post) => {
              let patched = AdminPost::new(
                id,
                title,
                slug,
                excerpt,
                content,
                slide_flag,
                post.status,
                post.published_at,
                post.updated_at,
              )
              return html_response(render_post_edit(patched, errors), 400)
            }
            None => return not_found_response()
          }
        }
        let now = now_iso()
        update_post(db, id, title, slug, excerpt, content, slide_flag, now) catch {
          _ =>
            return html_response(
              render_error_page("Database Error", "Failed to update post."),
              500,
            )
        }
        return redirect_to("/admin/posts/" + id.to_string() + "/edit")
      }
      None => not_found_response()
    }
  }
  if segments.length() == 4 &&
    segments[0] == "admin" &&
    segments[1] == "posts" &&
    segments[3] == "delete" {
    return match parse_id(segments[2]) {
      Some(id) => {
        delete_post(db, id) catch {
          _ =>
            return html_response(
              render_error_page("Database Error", "Failed to delete post."),
              500,
            )
        }
        return redirect_to("/admin")
      }
      None => not_found_response()
    }
  }
  if segments.length() == 4 &&
    segments[0] == "admin" &&
    segments[1] == "posts" &&
    segments[3] == "publish" {
    return match parse_id(segments[2]) {
      Some(id) => {
        let now = now_iso()
        set_status(db, id, Published, Some(now), now) catch {
          _ =>
            return html_response(
              render_error_page("Database Error", "Failed to publish post."),
              500,
            )
        }
        return redirect_to("/admin/posts/" + id.to_string() + "/edit")
      }
      None => not_found_response()
    }
  }
  if segments.length() == 4 &&
    segments[0] == "admin" &&
    segments[1] == "posts" &&
    segments[3] == "unpublish" {
    return match parse_id(segments[2]) {
      Some(id) => {
        let now = now_iso()
        set_status(db, id, Draft, None, now) catch {
          _ =>
            return html_response(
              render_error_page("Database Error", "Failed to unpublish post."),
              500,
            )
        }
        return redirect_to("/admin/posts/" + id.to_string() + "/edit")
      }
      None => not_found_response()
    }
  }
  not_found_response()
}

// =============================================================================
// Main Request Handler
// =============================================================================

///|
pub async fn handle_admin_request(
  req : @cloudflare.CloudflareRequest,
  env : @cloudflare.CloudflareEnv,
  _ctx : @cloudflare.CloudflareContext,
) -> @http.Response? {
  let url = parse_url(req.url)
  let pathname = get_pathname(url)
  if not(pathname.has_prefix("/admin")) {
    return None
  }
  let http_req = as_http_request(req)
  let segments = path_segments(pathname)
  let http_method = http_req.method_().to_upper()
  //
  // Route: Auth pages and API (public)
  // GET /admin/login
  if http_method == "GET" &&
    segments.length() == 2 &&
    segments[0] == "admin" &&
    segments[1] == "login" {
    return Some(handle_login_page())
  }
  // GET /admin/register (no token required - token entered via form)
  if http_method == "GET" &&
    segments.length() == 2 &&
    segments[0] == "admin" &&
    segments[1] == "register" {
    return Some(handle_register_page())
  }
  //
  // Route: Auth API (public, needs KV)
  let kv = match get_admin_auth_kv(env) {
    Some(k) => k
    None =>
      return Some(
        json_response("{\"error\":\"ADMIN_AUTH KV not configured\"}", 500),
      )
  }
  // GET /admin/login/options
  if http_method == "GET" &&
    segments.length() == 3 &&
    segments[0] == "admin" &&
    segments[1] == "login" &&
    segments[2] == "options" {
    let res : @http.Response = handle_login_options(kv, env)
    return Some(res)
  }
  // POST /admin/login/verify
  if http_method == "POST" &&
    segments.length() == 3 &&
    segments[0] == "admin" &&
    segments[1] == "login" &&
    segments[2] == "verify" {
    let res : @http.Response = handle_login_verify(kv, env, http_req)
    return Some(res)
  }
  // GET /admin/register/options (requires setup token in header only)
  if http_method == "GET" &&
    segments.length() == 3 &&
    segments[0] == "admin" &&
    segments[1] == "register" &&
    segments[2] == "options" {
    if not(has_valid_setup_token_header(http_req, env)) {
      return Some(forbidden_json_response())
    }
    let res : @http.Response = handle_register_options(kv, env)
    return Some(res)
  }
  // POST /admin/register/verify (requires setup token in header only)
  if http_method == "POST" &&
    segments.length() == 3 &&
    segments[0] == "admin" &&
    segments[1] == "register" &&
    segments[2] == "verify" {
    if not(has_valid_setup_token_header(http_req, env)) {
      return Some(forbidden_json_response())
    }
    let res : @http.Response = handle_register_verify(kv, env, http_req)
    return Some(res)
  }
  // POST /admin/logout
  if http_method == "POST" &&
    segments.length() == 2 &&
    segments[0] == "admin" &&
    segments[1] == "logout" {
    return Some(handle_logout(env))
  }
  //
  // Protected routes - require JWT authentication
  match require_auth(http_req, env, pathname) {
    Ok(_) => () // Authenticated (or public path, but we handled those above)
    Err(res) => return Some(res) // Redirect to login or 401
  }
  //
  // Get database for protected routes
  let db = match get_d1(env) {
    Some(value) => value
    None =>
      return Some(
        html_response(
          render_error_page("Database Error", "BLOG_DB is not configured."),
          500,
        ),
      )
  }
  //
  // Handle protected routes
  if http_method == "GET" {
    let res : @http.Response = handle_protected_get(db, segments)
    Some(res)
  } else if http_method == "POST" {
    let res : @http.Response = handle_protected_post(db, http_req, segments)
    Some(res)
  } else {
    Some(method_not_allowed_response())
  }
}

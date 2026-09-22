///|
const MCP_MAX_BODY_BYTES : Int = 1048576

///|
const MCP_SERVER_NAME : String = "f4ah6o/blog.mbt"

///|
const MCP_SERVER_VERSION : String = "0.1.0"

///|
pub fn mcp_auth_status(decision : @oauth.ProtectedResourceAuthorization) -> Int {
  match decision {
    @oauth.ProtectedResourceAuthorization::Authorized(_) => 200
    @oauth.ProtectedResourceAuthorization::MissingToken => 401
    @oauth.ProtectedResourceAuthorization::InvalidToken => 401
    @oauth.ProtectedResourceAuthorization::InsufficientScope => 403
    @oauth.ProtectedResourceAuthorization::InvalidConfiguration => 500
    @oauth.ProtectedResourceAuthorization::ServerError => 500
  }
}

///|
pub fn mcp_auth_challenge_error(
  decision : @oauth.ProtectedResourceAuthorization,
) -> String? {
  match decision {
    @oauth.ProtectedResourceAuthorization::MissingToken => None
    @oauth.ProtectedResourceAuthorization::InvalidToken => Some("invalid_token")
    @oauth.ProtectedResourceAuthorization::InsufficientScope =>
      Some("insufficient_scope")
    _ => None
  }
}

///|
pub fn mcp_http_preflight_status(
  http_method : String,
  content_type : String,
  accept : String,
) -> Int {
  if http_method != "POST" {
    405
  } else if content_type != "application/json" {
    415
  } else if !@mcp.valid_streamable_http_accept(accept) {
    406
  } else {
    200
  }
}

///|
fn mcp_protocol_headers(
  req : @cloudflare.CloudflareRequest,
) -> @mcp.HttpHeaders {
  let entries : Array[(String, String)] = []
  match mcp_request_header(req, @mcp.MCP_PROTOCOL_VERSION_HEADER) {
    Some(value) => entries.push((@mcp.MCP_PROTOCOL_VERSION_HEADER, value))
    None => ()
  }
  match mcp_request_header(req, @mcp.MCP_METHOD_HEADER) {
    Some(value) => entries.push((@mcp.MCP_METHOD_HEADER, value))
    None => ()
  }
  match mcp_request_header(req, @mcp.MCP_NAME_HEADER) {
    Some(value) => entries.push((@mcp.MCP_NAME_HEADER, value))
    None => ()
  }
  @mcp.HttpHeaders::new(entries)
}

///|
pub async fn handle_mcp_request(
  req : @cloudflare.CloudflareRequest,
  env : @cloudflare.CloudflareEnv,
  pathname : String,
  http_method : String,
) -> @http.Response? {
  if pathname != "/mcp" {
    return None
  }
  let content_type = mcp_content_type(req)
  let accept = mcp_request_header(req, "Accept").unwrap_or("")
  let preflight = mcp_http_preflight_status(http_method, content_type, accept)
  if preflight != 200 {
    return Some(mcp_empty_response_js(preflight, "", preflight == 405))
  }
  let db_value = get_db_from_env(env)
  if @core.typeof_(db_value) == "undefined" || @core.is_null(db_value) {
    return Some(mcp_empty_response_js(503, "", false))
  }
  let db : @cloudflare.D1Database = @core.identity(db_value)
  let authorization = mcp_request_header(req, "Authorization")
  let auth = @oauth.authorize_protected_resource(
    db,
    @config.SITE_URL,
    authorization,
    @oauth.SCOPE_MCP_DISCOVER,
    mcp_now(),
  ) catch {
    _ => @oauth.ProtectedResourceAuthorization::ServerError
  }
  let auth_status = mcp_auth_status(auth)
  if auth_status != 200 {
    let challenge = match
      @oauth.protected_resource_challenge(
        @config.SITE_URL,
        @oauth.SCOPE_MCP_DISCOVER,
        mcp_auth_challenge_error(auth),
      ) {
      Some(value) if auth_status == 401 || auth_status == 403 => value
      _ => ""
    }
    return Some(mcp_empty_response_js(auth_status, challenge, false))
  }
  let http_req : @http.Request = @core.identity(req)
  let body = http_req.text()
  if mcp_utf8_length(body) > MCP_MAX_BODY_BYTES {
    return Some(mcp_empty_response_js(413, "", false))
  }
  match
    @mcp.dispatch_mcp_http_request(
      body,
      mcp_protocol_headers(req),
      MCP_SERVER_NAME,
      MCP_SERVER_VERSION,
    ) {
    @mcp.McpDispatch::Respond(result) =>
      Some(mcp_json_response_js(result.body(), result.status()))
    @mcp.McpDispatch::ToolCall(id~, call~) => {
      // tools/call additionally requires the operation's scope on top of the
      // endpoint-wide mcp:discover check above.
      let tool_auth = @oauth.authorize_protected_resource(
        db,
        @config.SITE_URL,
        authorization,
        mcp_tool_required_scope(call),
        mcp_now(),
      ) catch {
        _ => @oauth.ProtectedResourceAuthorization::ServerError
      }
      let tool_status = mcp_auth_status(tool_auth)
      if tool_status != 200 {
        let challenge = match
          @oauth.protected_resource_challenge(
            @config.SITE_URL,
            mcp_tool_required_scope(call),
            mcp_auth_challenge_error(tool_auth),
          ) {
          Some(value) if tool_status == 401 || tool_status == 403 => value
          _ => ""
        }
        return Some(mcp_empty_response_js(tool_status, challenge, false))
      }
      let result_body = execute_mcp_tool(db, call, id) catch {
        _ => @mcp.tools_call_error(id, "Tool execution failed.")
      }
      Some(mcp_json_response_js(result_body, 200))
    }
  }
}

///|
/// Map a validated tool call to the OAuth scope its D1 operation requires.
fn mcp_tool_required_scope(call : @mcp.McpToolCall) -> String {
  match call {
    @mcp.McpToolCall::ListPosts(..) | @mcp.McpToolCall::GetPost(..) =>
      @oauth.SCOPE_READ
    @mcp.McpToolCall::CreatePost(..) | @mcp.McpToolCall::UpdatePost(..) =>
      @oauth.SCOPE_WRITE
    @mcp.McpToolCall::PublishPost(..) => @oauth.SCOPE_PUBLISH
  }
}

///|
fn admin_post_json(post : @admin.AdminPost) -> Json {
  @mcp.mcp_post_json(
    post.id,
    post.title,
    post.slug,
    post.excerpt,
    post.content,
    post.slide_flag,
    @admin.post_status_to_string(post.status),
    post.published_at,
    post.updated_at,
  )
}

///|
/// Mirror the admin form contract: title and slug are required, and slide
/// posts must carry valid slide markdown. Returns the error to surface.
fn validate_mcp_post_input(
  title : String,
  slug : String,
  content : String,
  slide_flag : Bool,
) -> String? {
  if title.trim().is_empty() {
    return Some("Title is required.")
  }
  if slug.trim().is_empty() {
    return Some("Slug is required.")
  }
  if slide_flag {
    match @lib.validate_slide_markdown(content) {
      Some(message) => return Some(message)
      None => ()
    }
  }
  None
}

///|
/// Re-read a post after a mutation so the tool result always reflects the
/// persisted row.
async fn mcp_post_result(db : @core.Any, id : Int, rpc_id : Json) -> String {
  let post_opt = @admin.get_post_by_id(db, id) catch {
    _ => return @mcp.tools_call_error(rpc_id, "Failed to load post.")
  }
  match post_opt {
    Some(post) =>
      @mcp.tools_call_result(rpc_id, ({ "post": admin_post_json(post) } : Json))
    None => @mcp.tools_call_error(rpc_id, "Post not found.")
  }
}

///|
/// Execute one validated tool call against D1. Execution failures surface as
/// `isError` tool results, never as JSON-RPC errors.
async fn execute_mcp_tool(
  db : @cloudflare.D1Database,
  call : @mcp.McpToolCall,
  rpc_id : Json,
) -> String {
  let db_any : @core.Any = @core.identity(db)
  match call {
    @mcp.McpToolCall::ListPosts(limit~, offset~) => {
      let posts = @admin.list_posts(db_any, limit, offset) catch {
        _ => return @mcp.tools_call_error(rpc_id, "Failed to list posts.")
      }
      let items : Array[Json] = []
      for post in posts {
        items.push(admin_post_json(post))
      }
      @mcp.tools_call_result(rpc_id, ({ "posts": items } : Json))
    }
    @mcp.McpToolCall::GetPost(id=post_id) =>
      mcp_post_result(db_any, post_id, rpc_id)
    @mcp.McpToolCall::CreatePost(title~, slug~, excerpt~, content~, slide_flag~) => {
      match validate_mcp_post_input(title, slug, content, slide_flag) {
        Some(message) => return @mcp.tools_call_error(rpc_id, message)
        None => ()
      }
      let new_id = @admin.insert_post(
        db_any,
        title,
        slug,
        excerpt,
        content,
        slide_flag,
        mcp_now_iso(),
      ) catch {
        _ => return @mcp.tools_call_error(rpc_id, "Failed to create post.")
      }
      if new_id == 0 {
        return @mcp.tools_call_error(rpc_id, "Failed to create post.")
      }
      mcp_post_result(db_any, new_id, rpc_id)
    }
    @mcp.McpToolCall::UpdatePost(
      id=post_id,
      title~,
      slug~,
      excerpt~,
      content~,
      slide_flag~
    ) => {
      match validate_mcp_post_input(title, slug, content, slide_flag) {
        Some(message) => return @mcp.tools_call_error(rpc_id, message)
        None => ()
      }
      let existing = @admin.get_post_by_id(db_any, post_id) catch {
        _ => return @mcp.tools_call_error(rpc_id, "Failed to load post.")
      }
      if existing is None {
        return @mcp.tools_call_error(rpc_id, "Post not found.")
      }
      @admin.update_post(
        db_any,
        post_id,
        title,
        slug,
        excerpt,
        content,
        slide_flag,
        mcp_now_iso(),
      ) catch {
        _ => return @mcp.tools_call_error(rpc_id, "Failed to update post.")
      }
      mcp_post_result(db_any, post_id, rpc_id)
    }
    @mcp.McpToolCall::PublishPost(id=post_id) => {
      let existing = @admin.get_post_by_id(db_any, post_id) catch {
        _ => return @mcp.tools_call_error(rpc_id, "Failed to load post.")
      }
      if existing is None {
        return @mcp.tools_call_error(rpc_id, "Post not found.")
      }
      let now = mcp_now_iso()
      @admin.set_status(
        db_any,
        post_id,
        @admin.post_status_from_string("published"),
        Some(now),
        now,
      ) catch {
        _ => return @mcp.tools_call_error(rpc_id, "Failed to publish post.")
      }
      mcp_post_result(db_any, post_id, rpc_id)
    }
  }
}

///|
extern "js" fn mcp_now_iso() -> String =
  #| () => new Date().toISOString()

///|
extern "js" fn mcp_request_header(
  req : @cloudflare.CloudflareRequest,
  name : String,
) -> String? =
  #| (request, name) => {
  #|   const value = request.headers.get(name)
  #|   return value === null ? undefined : value
  #| }

///|
extern "js" fn mcp_content_type(req : @cloudflare.CloudflareRequest) -> String =
  #| (request) => (request.headers.get("content-type") || "").split(";", 1)[0].trim().toLowerCase()

///|
extern "js" fn mcp_utf8_length(body : String) -> Int =
  #| (body) => new TextEncoder().encode(body).byteLength

///|
extern "js" fn mcp_now() -> Int =
  #| () => Math.floor(Date.now() / 1000)

///|
extern "js" fn mcp_json_response_js(
  body : String,
  status : Int,
) -> @http.Response =
  #| (body, status) => new Response(body, {
  #|   status,
  #|   headers: { "Content-Type": "application/json; charset=utf-8" },
  #| })

///|
extern "js" fn mcp_empty_response_js(
  status : Int,
  challenge : String,
  allow_post : Bool,
) -> @http.Response =
  #| (status, challenge, allowPost) => {
  #|   const headers = new Headers()
  #|   if (challenge) headers.set("WWW-Authenticate", challenge)
  #|   if (allowPost) headers.set("Allow", "POST")
  #|   return new Response(null, { status, headers })
  #| }

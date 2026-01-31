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
async fn handle_get(db : @core.Any, segments : Array[String]) -> @http.Response {
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
    return html_response(render_post_new("", "", "", "", []), 200)
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
async fn handle_post(
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
    let errors = validate_post_form(title, slug)
    if errors.length() > 0 {
      return html_response(
        render_post_new(title, slug, excerpt, content, errors),
        400,
      )
    }
    let now = now_iso()
    let new_id = insert_post(db, title, slug, excerpt, content, now) catch {
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
        let errors = validate_post_form(title, slug)
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
        update_post(db, id, title, slug, excerpt, content, now) catch {
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

///|
pub async fn handle_admin_request(
  req : @cloudflare.CloudflareRequest,
  env : @cloudflare.CloudflareEnv,
  _ctx : @cloudflare.CloudflareContext,
) -> @http.Response? {
  let url = parse_url(req.url)
  let pathname = get_pathname(url)
  if !pathname.has_prefix("/admin") {
    return None
  }
  let http_req = as_http_request(req)
  match require_basic_auth(http_req, env) {
    Ok(_) => ()
    Err(res) => return Some(res)
  }
  let db_opt = get_d1(env)
  let db = match db_opt {
    Some(value) => value
    None =>
      return Some(
        html_response(
          render_error_page("Database Error", "BLOG_DB is not configured."),
          500,
        ),
      )
  }
  let segments = path_segments(pathname)
  let http_method = http_req.method_().to_upper()
  if http_method == "GET" {
    let res : @http.Response = handle_get(db, segments)
    Some(res)
  } else if http_method == "POST" {
    let res : @http.Response = handle_post(db, http_req, segments)
    Some(res)
  } else {
    Some(method_not_allowed_response())
  }
}

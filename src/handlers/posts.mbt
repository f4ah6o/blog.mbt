///|
const DEFAULT_LIMIT : Int = 10

///|
const MAX_LIMIT : Int = 50

///|
fn parse_page(value : String?) -> Int {
  match value {
    Some(v) =>
      match @global.parse_int(v) {
        Some(n) => if n >= 1 { n } else { 1 }
        None => 1
      }
    None => 1
  }
}

///|
fn parse_limit(value : String?) -> Int {
  match value {
    Some(v) =>
      match @global.parse_int(v) {
        Some(n) =>
          if n < 1 {
            DEFAULT_LIMIT
          } else if n > MAX_LIMIT {
            MAX_LIMIT
          } else {
            n
          }
        None => DEFAULT_LIMIT
      }
    None => DEFAULT_LIMIT
  }
}

///|
fn ceil_div(a : Int, b : Int) -> Int {
  (a + b - 1) / b
}

///|
fn row_to_post(row : @core.Any) -> @models.BlogPost {
  let id = @cloudflare.js_number_to_int(row["id"])
  let title : String = row["title"].cast()
  let slug : String = row["slug"].cast()
  let excerpt_raw = row["excerpt"]
  let excerpt : String = if @core.is_null(excerpt_raw) {
    ""
  } else {
    excerpt_raw.cast()
  }
  let content : String = row["content"].cast()
  let published_at : String = row["published_at"].cast()
  let updated_at : String = row["updated_at"].cast()
  @models.BlogPost::new(
    id, title, slug, excerpt, content, published_at, updated_at,
  )
}

///|
pub async fn handle_posts_page(
  url : @url.URL,
  db : @cloudflare.D1Database,
) -> @http.Response {
  let params = url.searchParams()
  let page = parse_page(params.get("page"))
  let limit = parse_limit(params.get("limit"))
  let offset = (page - 1) * limit

  // Count total posts
  let count_val = db
    .prepare("SELECT COUNT(*) as count FROM posts WHERE status = 'published'")
    .first_col("count") catch {
      _ =>
        return @http.Response::html(
          @templates.error_layout("500 Error", "Database error occurred."),
          500,
        )
    }
  let total = match count_val {
    Some(c) => @cloudflare.js_number_to_int(c)
    None => 0
  }
  let total_pages = if total == 0 { 1 } else { ceil_div(total, limit) }

  // List posts
  let result = db
    .prepare(
      "SELECT * FROM posts WHERE status = 'published' ORDER BY published_at DESC LIMIT ? OFFSET ?",
    )
    .bind2(@core.any(limit), @core.any(offset))
    .all() catch {
      _ =>
        return @http.Response::html(
          @templates.error_layout("500 Error", "Database error occurred."),
          500,
        )
    }
  let rows = result.get_results()
  let posts : Array[@models.BlogPost] = []
  for row in rows {
    posts.push(row_to_post(row))
  }
  let content = @templates.post_list_content(posts, page, total_pages, limit)
  let html = @templates.layout("Posts - MoonBit Blog", content)
  @http.Response::html(html, 200)
}

///|
pub async fn handle_posts_partial(
  url : @url.URL,
  db : @cloudflare.D1Database,
) -> @http.Response {
  let params = url.searchParams()
  let page = parse_page(params.get("page"))
  let limit = parse_limit(params.get("limit"))
  let offset = (page - 1) * limit

  // Count total posts
  let count_val = db
    .prepare("SELECT COUNT(*) as count FROM posts WHERE status = 'published'")
    .first_col("count") catch {
      _ =>
        return html_response(
          "<div class=\"error-panel\">Database error occurred.</div>", 500,
        )
    }
  let total = match count_val {
    Some(c) => @cloudflare.js_number_to_int(c)
    None => 0
  }
  let total_pages = if total == 0 { 1 } else { ceil_div(total, limit) }

  // List posts
  let result = db
    .prepare(
      "SELECT * FROM posts WHERE status = 'published' ORDER BY published_at DESC LIMIT ? OFFSET ?",
    )
    .bind2(@core.any(limit), @core.any(offset))
    .all() catch {
      _ =>
        return html_response(
          "<div class=\"error-panel\">Database error occurred.</div>", 500,
        )
    }
  let rows = result.get_results()
  let posts : Array[@models.BlogPost] = []
  for row in rows {
    posts.push(row_to_post(row))
  }
  let html = @templates.render_post_list(posts, page, total_pages, limit)
  html_response(html, 200)
}

///|
pub async fn handle_post_detail(
  slug : String,
  db : @cloudflare.D1Database,
) -> @http.Response {
  let row = db
    .prepare("SELECT * FROM posts WHERE slug = ? AND status = 'published'")
    .bind1(@core.any(slug))
    .first() catch {
      _ =>
        return @http.Response::html(
          @templates.error_layout("500 Error", "Database error occurred."),
          500,
        )
    }
  match row {
    Some(r) => {
      let post = row_to_post(r)
      let content = @templates.post_detail_content(post)
      let html = @templates.layout(post.title + " - MoonBit Blog", content)
      @http.Response::html(html, 200)
    }
    None =>
      @http.Response::html(
        @templates.error_layout(
          "404 Not Found", "The requested post was not found.",
        ),
        404,
      )
  }
}

///|
fn html_response(body : String, status : Int) -> @http.Response {
  let headers = @core.new_object()
  headers["Content-Type"] = @core.any("text/html; charset=utf-8")
  @http.Response::new(body~, status~, headers~)
}

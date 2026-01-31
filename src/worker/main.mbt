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
extern "js" fn html_response_js(body : String, status : Int) -> @http.Response =
  #| (body, status) => new Response(body, { status, headers: { "Content-Type": "text/html; charset=utf-8" } })

///|
extern "js" fn get_db_from_env(env : @cloudflare.CloudflareEnv) -> @core.Any =
  #| (env) => env.BLOG_DB

///|
extern "js" fn parse_url(url_str : String) -> @core.Any =
  #| (url_str) => new URL(url_str)

///|
extern "js" fn get_pathname(url : @core.Any) -> String =
  #| (url) => url.pathname

///|
extern "js" fn get_search_param(url : @core.Any, name : String) -> String? =
  #| (url, name) => url.searchParams.get(name)

///|
extern "js" fn db_count_posts(db : @core.Any) -> @core.Promise[Int] =
  #| async (db) => {
  #|   const result = await db.prepare("SELECT COUNT(*) as count FROM posts WHERE status = 'published'").first("count");
  #|   return result || 0;
  #| }

///|
extern "js" fn db_list_posts(
  db : @core.Any,
  limit : Int,
  offset : Int,
) -> @core.Promise[@core.Any] =
  #| async (db, limit, offset) => {
  #|   const result = await db.prepare("SELECT * FROM posts WHERE status = 'published' ORDER BY published_at DESC LIMIT ? OFFSET ?").bind(limit, offset).all();
  #|   return result.results || [];
  #| }

///|
extern "js" fn db_get_post_by_slug(
  db : @core.Any,
  slug : String,
) -> @core.Promise[@core.Any] =
  #| async (db, slug) => {
  #|   return await db.prepare("SELECT * FROM posts WHERE slug = ? AND status = 'published'").bind(slug).first();
  #| }

///|
pub fn get_fetch_handler() -> @cloudflare.CloudflareFetchHandler {
  @core.identity(async fn(
    req : @cloudflare.CloudflareRequest,
    env : @cloudflare.CloudflareEnv,
    _ctx : @cloudflare.CloudflareContext,
  ) -> @http.Response {
    match @admin.handle_admin_request(req, env, _ctx) {
      Some(res) => res
      None => {
        let url = parse_url(req.url)
        let pathname = get_pathname(url)
        let db = get_db_from_env(env)

        // Check if database is available
        if @core.typeof_(db) == "undefined" {
          return html_response_js(
            "<!DOCTYPE html><html><body><h1>500 Error</h1><p>Database not configured</p></body></html>",
            500,
          )
        }

        // Route: /api/posts (partial HTML for MHX)
        if pathname == "/api/posts" {
          let page = parse_page(get_search_param(url, "page"))
          let limit = parse_limit(get_search_param(url, "limit"))
          let offset = (page - 1) * limit
          let total = db_count_posts(db).wait()
          let total_pages = if total == 0 { 1 } else { ceil_div(total, limit) }
          let rows_any = db_list_posts(db, limit, offset).wait()
          let posts : Array[@models.BlogPost] = []
          let rows_arr : Array[@core.Any] = rows_any.cast()
          for row in rows_arr {
            posts.push(row_to_post(row))
          }
          let html = @templates.render_post_list(
            posts, page, total_pages, limit,
          )
          return html_response_js(html, 200)
        }

        // Route: /posts/:slug (post detail)
        match extract_slug(pathname) {
          Some(slug) => {
            let row = db_get_post_by_slug(db, slug).wait()
            if @core.is_null(row) {
              return html_response_js(
                @templates.error_layout(
                  "404 Not Found", "The requested post was not found.",
                ),
                404,
              )
            } else {
              let post = row_to_post(row)
              let content = @templates.post_detail_content(post)
              let html = @templates.layout(
                post.title + " - " + @config.SITE_TITLE,
                content,
              )
              return html_response_js(html, 200)
            }
          }
          None => ()
        }

        // Route: / or /posts (post list page)
        if pathname == "/" || pathname == "/posts" {
          let page = parse_page(get_search_param(url, "page"))
          let limit = parse_limit(get_search_param(url, "limit"))
          let offset = (page - 1) * limit
          let total = db_count_posts(db).wait()
          let total_pages = if total == 0 { 1 } else { ceil_div(total, limit) }
          let rows_any = db_list_posts(db, limit, offset).wait()
          let posts : Array[@models.BlogPost] = []
          let rows_arr : Array[@core.Any] = rows_any.cast()
          for row in rows_arr {
            posts.push(row_to_post(row))
          }
          let content = @templates.post_list_content(
            posts, page, total_pages, limit,
          )
          let html = @templates.layout("Posts - " + @config.SITE_TITLE, content)
          return html_response_js(html, 200)
        }

        // 404 for unknown routes
        html_response_js(
          "<!DOCTYPE html><html><body><h1>404 Not Found</h1><p>The requested page was not found.</p></body></html>",
          404,
        )
      }
    }
  })
}

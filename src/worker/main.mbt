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
extern "js" fn markdown_response_js(
  body : String,
  status : Int,
) -> @http.Response =
  #| (body, status) => new Response(body, { status, headers: { "Content-Type": "text/markdown; charset=utf-8" } })

///|
extern "js" fn text_response_js(body : String, status : Int) -> @http.Response =
  #| (body, status) => new Response(body, { status, headers: { "Content-Type": "text/plain; charset=utf-8" } })

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
extern "js" fn fetch_url(url : String) -> @core.Promise[String] =
  #| async (url) => {
  #|   try {
  #|     const response = await fetch(url, {
  #|       headers: {
  #|         'User-Agent': 'Mozilla/5.0 (compatible; BlogBot/1.0)',
  #|         'Accept': 'text/html,application/xhtml+xml'
  #|       },
  #|       redirect: 'follow'
  #|     });
  #|     if (!response.ok) return '';
  #|     const text = await response.text();
  #|     return text.substring(0, 50000);
  #|   } catch (e) {
  #|     return '';
  #|   }
  #| }

///|
extern "js" fn json_response(body : String, status : Int) -> @http.Response =
  #| (body, status) => new Response(body, { status, headers: { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*" } })

///|
fn strip_md_suffix(slug : String) -> String? {
  if slug.has_suffix(".md") && slug.length() > 3 {
    let view = try! slug[:slug.length() - 3]
    let base_slug = view.to_string()
    if base_slug.length() == 0 {
      None
    } else {
      Some(base_slug)
    }
  } else {
    None
  }
}

///|
fn absolute_post_url(slug : String) -> String {
  let base = @config.SITE_URL
  if base.has_suffix("/") {
    base + "posts/" + slug
  } else {
    base + "/posts/" + slug
  }
}

///|
fn yaml_quote(value : String) -> String {
  let sb = StringBuilder::new()
  sb.write_char('"')
  for ch in value {
    match ch {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(ch)
    }
  }
  sb.write_char('"')
  sb.to_string()
}

///|
fn render_markdown_with_front_matter(post : @models.BlogPost) -> String {
  let sb = StringBuilder::new()
  sb.write_string("---\n")
  sb.write_string("title: ")
  sb.write_string(yaml_quote(post.title))
  sb.write_char('\n')
  sb.write_string("slug: ")
  sb.write_string(yaml_quote(post.slug))
  sb.write_char('\n')
  sb.write_string("excerpt: ")
  sb.write_string(yaml_quote(post.excerpt))
  sb.write_char('\n')
  sb.write_string("published_at: ")
  sb.write_string(yaml_quote(post.published_at))
  sb.write_char('\n')
  sb.write_string("updated_at: ")
  sb.write_string(yaml_quote(post.updated_at))
  sb.write_char('\n')
  sb.write_string("url: ")
  sb.write_string(yaml_quote(absolute_post_url(post.slug)))
  sb.write_string("\n---\n\n")
  sb.write_string(post.content)
  sb.to_string()
}

///|
async fn get_post_by_slug(db : @core.Any, slug : String) -> @models.BlogPost? {
  let row = db_get_post_by_slug(db, slug).wait()
  if @core.is_null(row) {
    None
  } else {
    Some(row_to_post(row))
  }
}

///|
fn json_escape(s : String) -> String {
  let sb = StringBuilder::new()
  sb.write_char('"')
  for ch in s {
    match ch {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(ch)
    }
  }
  sb.write_char('"')
  sb.to_string()
}

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

        // Route: /api/ogp (OGP data fetch)
        if pathname == "/api/ogp" {
          let target_url = get_search_param(url, "url")
          match target_url {
            Some(u) => {
              let html = fetch_url(u).wait()
              if html.length() == 0 {
                return json_response(
                  "{\"error\": \"Failed to fetch URL\"}", 500,
                )
              }
              let ogp = @lib.parse_ogp_from_html(html)
              let json = "{\"title\": " +
                json_escape(ogp.title) +
                ", \"description\": " +
                json_escape(ogp.description) +
                ", \"image\": " +
                json_escape(ogp.image) +
                ", \"site_name\": " +
                json_escape(ogp.site_name) +
                "}"
              return json_response(json, 200)
            }
            None =>
              return json_response(
                "{\"error\": \"Missing url parameter\"}", 400,
              )
          }
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
            // Route: /posts/:slug.md (raw markdown with front matter)
            match strip_md_suffix(slug) {
              Some(base_slug) => {
                let post_opt = match get_post_by_slug(db, base_slug) {
                  Some(post) => Some(post)
                  // Compatibility: if slug itself exists with ".md", serve it too.
                  None => get_post_by_slug(db, slug)
                }
                match post_opt {
                  Some(post) =>
                    return markdown_response_js(
                      render_markdown_with_front_matter(post),
                      200,
                    )
                  None =>
                    return text_response_js(
                      "404 Not Found\nThe requested markdown post was not found.\n",
                      404,
                    )
                }
              }
              None => ()
            }

            match get_post_by_slug(db, slug) {
              None =>
                return html_response_js(
                  @templates.error_layout(
                    "404 Not Found", "The requested post was not found.",
                  ),
                  404,
                )
              Some(post) => {
              // Extract embed URLs and fetch data
                let embed_urls = @lib.extract_embed_urls(post.content)
                let embed_data : @hashmap.HashMap[String, @lib.EmbedData] = @hashmap.new()
                for embed_url in embed_urls {
                  // Check if it's a YouTube URL
                  match @lib.parse_youtube_url(embed_url) {
                    Some(video_id) => {
                      embed_data[embed_url] = @lib.EmbedData::youtube(video_id)
                      continue
                    }
                    None => ()
                  }
                  // Otherwise fetch OGP for card
                  let html = fetch_url(embed_url).wait()
                  if html.length() > 0 {
                    let ogp = @lib.parse_ogp_from_html(html)
                    let card = @lib.ogp_to_link_card(ogp, embed_url)
                    embed_data[embed_url] = @lib.EmbedData::card(card)
                  }
                }
                let content = @templates.post_detail_content_with_embeds(
                  post, embed_data,
                )
                let html = @templates.layout(
                  post.title + " - " + @config.SITE_TITLE,
                  content,
                )
                return html_response_js(html, 200)
              }
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

///|
fn escape_html(value : String) -> String {
  let sb = StringBuilder::new()
  for ch in value {
    match ch {
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      '"' => sb.write_string("&quot;")
      '\'' => sb.write_string("&#39;")
      _ => sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
fn render_errors(errors : Array[String]) -> String {
  if errors.length() == 0 {
    return ""
  }
  let sb = StringBuilder::new()
  sb.write_string("<div class=\"errors\"><p>Fix the following:</p><ul>")
  for err in errors {
    sb.write_string("<li>")
    sb.write_string(escape_html(err))
    sb.write_string("</li>")
  }
  sb.write_string("</ul></div>")
  sb.to_string()
}

///|
fn admin_layout(title : String, body : String) -> String {
  let full_title = title + " - Admin"
  let sb = StringBuilder::new()
  sb.write_string("<!DOCTYPE html><html><head><meta charset=\"utf-8\">")
  sb.write_string(
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
  )
  sb.write_string("<title>")
  sb.write_string(escape_html(full_title))
  sb.write_string("</title>")
  sb.write_string(
    "<style>body{font-family:ui-sans-serif,system-ui,-apple-system,\"Segoe UI\",sans-serif;margin:0;background:#f6f6f3;color:#1d1d1b;}header{background:#111;color:#fff;padding:16px 24px;}header a{color:#fff;text-decoration:none;font-weight:700;}main{max-width:960px;margin:24px auto;padding:0 24px;}h1{margin:0 0 16px;}table{width:100%;border-collapse:collapse;background:#fff;}th,td{padding:12px;border-bottom:1px solid #e5e5e0;text-align:left;vertical-align:top;}th{background:#f2f2ed;}a{color:#1c5d99;}form.inline{display:inline;}button{padding:6px 12px;border-radius:6px;border:1px solid #ccc;background:#fff;cursor:pointer;}button.primary{background:#111;color:#fff;border-color:#111;}button.danger{background:#d64545;color:#fff;border-color:#d64545;}textarea,input[type=\"text\"]{width:100%;padding:8px;border-radius:6px;border:1px solid #ccc;font-family:inherit;}textarea{min-height:220px;}label{display:block;font-weight:600;margin:12px 0 6px;}nav.breadcrumbs{margin-bottom:16px;}nav.breadcrumbs a{margin-right:8px;}div.actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px;}div.errors{background:#ffecec;border:1px solid #f5b5b5;padding:12px;border-radius:6px;margin-bottom:16px;}span.badge{display:inline-block;padding:2px 8px;border-radius:999px;font-size:12px;background:#eee;}span.badge.published{background:#d6f5d6;}span.badge.draft{background:#f7e1b5;}</style>",
  )
  sb.write_string("</head><body>")
  sb.write_string("<header><a href=\"/admin\">Blog Admin</a></header>")
  sb.write_string("<main>")
  sb.write_string(body)
  sb.write_string("</main></body></html>")
  sb.to_string()
}

///|
fn render_error_page(title : String, message : String) -> String {
  let content = "<h1>" +
    escape_html(title) +
    "</h1><p>" +
    escape_html(message) +
    "</p>"
  admin_layout(title, content)
}

///|
fn render_post_form(
  heading : String,
  action : String,
  submit_label : String,
  title : String,
  slug : String,
  excerpt : String,
  content : String,
  errors : Array[String],
) -> String {
  let title_html = escape_html(title)
  let slug_html = escape_html(slug)
  let excerpt_html = escape_html(excerpt)
  let content_html = escape_html(content)
  let sb = StringBuilder::new()
  sb.write_string("<h1>")
  sb.write_string(escape_html(heading))
  sb.write_string("</h1>")
  sb.write_string(render_errors(errors))
  sb.write_string("<form method=\"post\" action=\"")
  sb.write_string(escape_html(action))
  sb.write_string("\">")
  sb.write_string("<label>Title</label>")
  sb.write_string("<input type=\"text\" name=\"title\" value=\"")
  sb.write_string(title_html)
  sb.write_string("\" required>")
  sb.write_string("<label>Slug</label>")
  sb.write_string("<input type=\"text\" name=\"slug\" value=\"")
  sb.write_string(slug_html)
  sb.write_string("\" required>")
  sb.write_string("<label>Excerpt</label>")
  sb.write_string("<textarea name=\"excerpt\">")
  sb.write_string(excerpt_html)
  sb.write_string("</textarea>")
  sb.write_string("<label>Content</label>")
  sb.write_string("<textarea name=\"content\">")
  sb.write_string(content_html)
  sb.write_string("</textarea>")
  sb.write_string("<div class=\"actions\">")
  sb.write_string("<button class=\"primary\" type=\"submit\">")
  sb.write_string(escape_html(submit_label))
  sb.write_string("</button>")
  sb.write_string("</div>")
  sb.write_string("</form>")
  sb.to_string()
}

///|
fn render_post_list(posts : Array[AdminPost]) -> String {
  let sb = StringBuilder::new()
  sb.write_string(
    "<nav class=\"breadcrumbs\"><a href=\"/admin\">Posts</a></nav>",
  )
  sb.write_string("<div class=\"actions\">")
  sb.write_string(
    "<a href=\"/admin/posts/new\"><button class=\"primary\">New Post</button></a>",
  )
  sb.write_string("</div>")
  sb.write_string("<table><thead><tr>")
  sb.write_string(
    "<th>Title</th><th>Status</th><th>Updated</th><th>Published</th><th>Actions</th>",
  )
  sb.write_string("</tr></thead><tbody>")
  for post in posts {
    let id_str = post.id.to_string()
    let title_html = escape_html(post.title)
    let slug_html = escape_html(post.slug)
    let status_label = post_status_label(post.status)
    let status_class = match post.status {
      Draft => "draft"
      Published => "published"
    }
    let updated_html = escape_html(post.updated_at)
    let published_html = match post.published_at {
      Some(ts) => escape_html(ts)
      None => "-"
    }
    sb.write_string("<tr>")
    sb.write_string("<td><strong>")
    sb.write_string(title_html)
    sb.write_string("</strong><div>")
    sb.write_string(slug_html)
    sb.write_string("</div></td>")
    sb.write_string("<td><span class=\"badge ")
    sb.write_string(status_class)
    sb.write_string("\">")
    sb.write_string(escape_html(status_label))
    sb.write_string("</span></td>")
    sb.write_string("<td>")
    sb.write_string(updated_html)
    sb.write_string("</td>")
    sb.write_string("<td>")
    sb.write_string(published_html)
    sb.write_string("</td>")
    sb.write_string("<td>")
    sb.write_string("<div class=\"actions\">")
    sb.write_string("<a href=\"/admin/posts/")
    sb.write_string(id_str)
    sb.write_string("/edit\"><button>Edit</button></a>")
    sb.write_string("<a href=\"/admin/preview/")
    sb.write_string(id_str)
    sb.write_string("\"><button>Preview</button></a>")
    sb.write_string("<a href=\"/posts/")
    sb.write_string(slug_html)
    sb.write_string("\"><button>Public</button></a>")
    match post.status {
      Draft => {
        sb.write_string(
          "<form class=\"inline\" method=\"post\" action=\"/admin/posts/",
        )
        sb.write_string(id_str)
        sb.write_string("/publish\">")
        sb.write_string(
          "<button class=\"primary\" type=\"submit\">Publish</button></form>",
        )
      }
      Published => {
        sb.write_string(
          "<form class=\"inline\" method=\"post\" action=\"/admin/posts/",
        )
        sb.write_string(id_str)
        sb.write_string("/unpublish\">")
        sb.write_string("<button type=\"submit\">Unpublish</button></form>")
      }
    }
    sb.write_string(
      "<form class=\"inline\" method=\"post\" action=\"/admin/posts/",
    )
    sb.write_string(id_str)
    sb.write_string(
      "/delete\" onsubmit=\"return confirm('Delete this post?')\">",
    )
    sb.write_string(
      "<button class=\"danger\" type=\"submit\">Delete</button></form>",
    )
    sb.write_string("</div>")
    sb.write_string("</td>")
    sb.write_string("</tr>")
  }
  sb.write_string("</tbody></table>")
  admin_layout("Posts", sb.to_string())
}

///|
fn render_post_new(
  title : String,
  slug : String,
  excerpt : String,
  content : String,
  errors : Array[String],
) -> String {
  let form_html = render_post_form(
    "New Post", "/admin/posts", "Create", title, slug, excerpt, content, errors,
  )
  admin_layout("New Post", form_html)
}

///|
fn render_post_edit(post : AdminPost, errors : Array[String]) -> String {
  let id_str = post.id.to_string()
  let form_html = render_post_form(
    "Edit Post",
    "/admin/posts/" + id_str,
    "Save",
    post.title,
    post.slug,
    post.excerpt,
    post.content,
    errors,
  )
  let status_label = post_status_label(post.status)
  let published_html = match post.published_at {
    Some(ts) => escape_html(ts)
    None => "-"
  }
  let sb = StringBuilder::new()
  sb.write_string(
    "<nav class=\"breadcrumbs\"><a href=\"/admin\">Posts</a> / Edit</nav>",
  )
  sb.write_string("<p>Status: <strong>")
  sb.write_string(escape_html(status_label))
  sb.write_string("</strong> | Published: ")
  sb.write_string(published_html)
  sb.write_string("</p>")
  sb.write_string(form_html)
  sb.write_string("<div class=\"actions\">")
  sb.write_string("<a href=\"/admin/preview/")
  sb.write_string(id_str)
  sb.write_string("\"><button>Preview</button></a>")
  match post.status {
    Draft => {
      sb.write_string(
        "<form class=\"inline\" method=\"post\" action=\"/admin/posts/",
      )
      sb.write_string(id_str)
      sb.write_string("/publish\">")
      sb.write_string(
        "<button class=\"primary\" type=\"submit\">Publish</button></form>",
      )
    }
    Published => {
      sb.write_string(
        "<form class=\"inline\" method=\"post\" action=\"/admin/posts/",
      )
      sb.write_string(id_str)
      sb.write_string("/unpublish\">")
      sb.write_string("<button type=\"submit\">Unpublish</button></form>")
    }
  }
  sb.write_string(
    "<form class=\"inline\" method=\"post\" action=\"/admin/posts/",
  )
  sb.write_string(id_str)
  sb.write_string("/delete\" onsubmit=\"return confirm('Delete this post?')\">")
  sb.write_string(
    "<button class=\"danger\" type=\"submit\">Delete</button></form>",
  )
  sb.write_string("</div>")
  admin_layout("Edit Post", sb.to_string())
}

///|
fn render_preview(post : AdminPost) -> String {
  let sb = StringBuilder::new()
  sb.write_string(
    "<nav class=\"breadcrumbs\"><a href=\"/admin\">Posts</a> / Preview</nav>",
  )
  sb.write_string("<article>")
  sb.write_string("<h1>")
  sb.write_string(escape_html(post.title))
  sb.write_string("</h1>")
  sb.write_string("<div class=\"meta\">")
  sb.write_string("Status: ")
  sb.write_string(escape_html(post_status_label(post.status)))
  sb.write_string("</div>")
  sb.write_string("<section>")
  sb.write_string(post.content)
  sb.write_string("</section>")
  sb.write_string("</article>")
  admin_layout("Preview", sb.to_string())
}

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
  let slide_flag = @cloudflare.js_number_to_int(row["slide_flag"]) == 1
  let published_at : String = row["published_at"].cast()
  let updated_at : String = row["updated_at"].cast()
  @models.BlogPost::new(
    id, title, slug, excerpt, content, slide_flag, published_at, updated_at,
  )
}

///|
pub async fn list_posts(
  db : @cloudflare.D1Database,
  limit : Int,
  offset : Int,
) -> Array[@models.BlogPost] raise @cloudflare.D1Error {
  let stmt = db.prepare(
    "SELECT * FROM posts WHERE status = 'published' ORDER BY published_at DESC LIMIT ? OFFSET ?",
  )
  let bound = stmt.bind2(@core.any(limit), @core.any(offset))
  let result = bound.all()
  let rows = result.get_results()
  let posts : Array[@models.BlogPost] = []
  for row in rows {
    posts.push(row_to_post(row))
  }
  posts
}

///|
pub async fn get_by_slug(
  db : @cloudflare.D1Database,
  slug : String,
) -> @models.BlogPost? raise @cloudflare.D1Error {
  let stmt = db.prepare(
    "SELECT * FROM posts WHERE slug = ? AND status = 'published'",
  )
  let bound = stmt.bind1(@core.any(slug))
  let row = bound.first()
  match row {
    Some(r) => Some(row_to_post(r))
    None => None
  }
}

///|
pub async fn count(
  db : @cloudflare.D1Database,
) -> Int raise @cloudflare.D1Error {
  let stmt = db.prepare(
    "SELECT COUNT(*) as count FROM posts WHERE status = 'published'",
  )
  let result = stmt.first_col("count")
  match result {
    Some(c) => @cloudflare.js_number_to_int(c)
    None => 0
  }
}

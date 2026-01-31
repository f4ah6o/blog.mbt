///|
fn any_string_or_empty(value : @core.Any) -> String {
  if @core.is_null(value) {
    ""
  } else {
    value.cast()
  }
}

///|
fn any_string_optional(value : @core.Any) -> String? {
  if @core.is_null(value) {
    None
  } else {
    Some(value.cast())
  }
}

///|
fn row_to_admin_post(row : @core.Any) -> AdminPost {
  let id = @cloudflare.js_number_to_int(row["id"])
  let title : String = row["title"].cast()
  let slug : String = row["slug"].cast()
  let excerpt = any_string_or_empty(row["excerpt"])
  let content : String = row["content"].cast()
  let status_raw = any_string_or_empty(row["status"])
  let status = post_status_from_string(status_raw)
  let published_at = any_string_optional(row["published_at"])
  let updated_at : String = row["updated_at"].cast()
  AdminPost::new(
    id, title, slug, excerpt, content, status, published_at, updated_at,
  )
}

///|
fn optional_string_or_null(value : String?) -> @core.Any {
  match value {
    Some(v) => @core.any(v)
    None => @core.null()
  }
}

///|
pub async fn list_posts(
  db : @core.Any,
  limit : Int,
  offset : Int,
) -> Array[AdminPost] {
  let rows = db_list_posts(db, limit, offset).wait()
  let posts : Array[AdminPost] = []
  for row in rows {
    posts.push(row_to_admin_post(row))
  }
  posts
}

///|
pub async fn count_posts(db : @core.Any) -> Int {
  db_count_posts(db).wait()
}

///|
pub async fn get_post_by_id(db : @core.Any, id : Int) -> AdminPost? {
  let row = db_get_post_by_id(db, id).wait()
  if @core.is_null(row) {
    None
  } else {
    Some(row_to_admin_post(row))
  }
}

///|
pub async fn insert_post(
  db : @core.Any,
  title : String,
  slug : String,
  excerpt : String,
  content : String,
  updated_at : String,
) -> Int {
  db_insert_post(
    db,
    title,
    slug,
    excerpt,
    content,
    "draft",
    @core.null(),
    updated_at,
  ).wait()
}

///|
pub async fn update_post(
  db : @core.Any,
  id : Int,
  title : String,
  slug : String,
  excerpt : String,
  content : String,
  updated_at : String,
) -> Unit {
  db_update_post(db, id, title, slug, excerpt, content, updated_at).wait()
}

///|
pub async fn delete_post(db : @core.Any, id : Int) -> Unit {
  db_delete_post(db, id).wait()
}

///|
pub async fn set_status(
  db : @core.Any,
  id : Int,
  status : PostStatus,
  published_at : String?,
  updated_at : String,
) -> Unit {
  db_set_status(
    db,
    id,
    post_status_to_string(status),
    optional_string_or_null(published_at),
    updated_at,
  ).wait()
}

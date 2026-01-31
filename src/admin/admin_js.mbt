///|
extern "js" fn parse_url(url_str : String) -> @core.Any =
  #| (url_str) => new URL(url_str)

///|
extern "js" fn get_pathname(url : @core.Any) -> String =
  #| (url) => url.pathname

///|
extern "js" fn decode_uri_component(value : String) -> String =
  #| (value) => decodeURIComponent(value)

///|
extern "js" fn decode_base64(value : String) -> String =
  #| (value) => {
  #|   if (typeof atob === "function") {
  #|     return atob(value)
  #|   }
  #|   return Buffer.from(value, "base64").toString("utf-8")
  #| }

///|
extern "js" fn now_iso() -> String =
  #| () => new Date().toISOString()

///|
extern "js" fn request_header(req : @http.Request, name : String) -> String? =
  #| (req, name) => {
  #|   const value = req.headers.get(name)
  #|   return value === null ? undefined : value
  #| }

///|
extern "js" fn db_list_posts(
  db : @core.Any,
  limit : Int,
  offset : Int,
) -> @core.Promise[Array[@core.Any]] =
  #| async (db, limit, offset) => {
  #|   const result = await db
  #|     .prepare("SELECT id, title, slug, excerpt, content, status, published_at, updated_at FROM posts ORDER BY updated_at DESC LIMIT ? OFFSET ?")
  #|     .bind(limit, offset)
  #|     .all();
  #|   return result.results || [];
  #| }

///|
extern "js" fn db_count_posts(db : @core.Any) -> @core.Promise[Int] =
  #| async (db) => {
  #|   const result = await db.prepare("SELECT COUNT(*) as count FROM posts").first("count");
  #|   return result || 0;
  #| }

///|
extern "js" fn db_get_post_by_id(
  db : @core.Any,
  id : Int,
) -> @core.Promise[@core.Any] =
  #| async (db, id) => {
  #|   return await db.prepare("SELECT id, title, slug, excerpt, content, status, published_at, updated_at FROM posts WHERE id = ?").bind(id).first();
  #| }

///|
extern "js" fn db_insert_post(
  db : @core.Any,
  title : String,
  slug : String,
  excerpt : String,
  content : String,
  status : String,
  published_at : @core.Any,
  updated_at : String,
) -> @core.Promise[Int] =
  #| async (db, title, slug, excerpt, content, status, published_at, updated_at) => {
  #|   const result = await db
  #|     .prepare("INSERT INTO posts (title, slug, excerpt, content, status, published_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)")
  #|     .bind(title, slug, excerpt, content, status, published_at, updated_at)
  #|     .run();
  #|   return (result.meta && result.meta.last_row_id) ? result.meta.last_row_id : 0;
  #| }

///|
extern "js" fn db_update_post(
  db : @core.Any,
  id : Int,
  title : String,
  slug : String,
  excerpt : String,
  content : String,
  updated_at : String,
) -> @core.Promise[Unit] =
  #| async (db, id, title, slug, excerpt, content, updated_at) => {
  #|   await db
  #|     .prepare("UPDATE posts SET title = ?, slug = ?, excerpt = ?, content = ?, updated_at = ? WHERE id = ?")
  #|     .bind(title, slug, excerpt, content, updated_at, id)
  #|     .run();
  #| }

///|
extern "js" fn db_delete_post(db : @core.Any, id : Int) -> @core.Promise[Unit] =
  #| async (db, id) => {
  #|   await db.prepare("DELETE FROM posts WHERE id = ?").bind(id).run();
  #| }

///|
extern "js" fn db_set_status(
  db : @core.Any,
  id : Int,
  status : String,
  published_at : @core.Any,
  updated_at : String,
) -> @core.Promise[Unit] =
  #| async (db, id, status, published_at, updated_at) => {
  #|   await db
  #|     .prepare("UPDATE posts SET status = ?, published_at = ?, updated_at = ? WHERE id = ?")
  #|     .bind(status, published_at, updated_at, id)
  #|     .run();
  #| }

///|
fn as_http_request(req : @cloudflare.CloudflareRequest) -> @http.Request {
  @core.identity(req)
}

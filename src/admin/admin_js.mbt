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

// =============================================================================
// KV Operations (Cloudflare Workers KV)
// =============================================================================

///|
/// Get value from KV namespace
extern "js" fn kv_get(kv : @core.Any, key : String) -> @core.Promise[String?] =
  #| async (kv, key) => {
  #|   const value = await kv.get(key, "text");
  #|   return value === null ? undefined : value;
  #| }

///|
/// Put value to KV namespace with optional TTL (in seconds)
extern "js" fn kv_put(
  kv : @core.Any,
  key : String,
  value : String,
  ttl_seconds : Int,
) -> @core.Promise[Unit] =
  #| async (kv, key, value, ttlSeconds) => {
  #|   const options = ttlSeconds > 0 ? { expirationTtl: ttlSeconds } : {};
  #|   await kv.put(key, value, options);
  #| }

///|
/// Delete value from KV namespace
extern "js" fn kv_delete(kv : @core.Any, key : String) -> @core.Promise[Unit] =
  #| async (kv, key) => {
  #|   await kv.delete(key);
  #| }

// =============================================================================
// JWT Operations (HS256 using Web Crypto API)
// =============================================================================

///|
/// Create JWT token with HS256 signature
/// payload should be a JSON string
extern "js" fn jwt_sign(
  payload : String,
  secret : String,
) -> @core.Promise[String] =
  #| async (payload, secret) => {
  #|   const encoder = new TextEncoder();
  #|   const header = { alg: "HS256", typ: "JWT" };
  #|   const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  #|   const payloadB64 = btoa(payload).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  #|   const data = headerB64 + "." + payloadB64;
  #|   const key = await crypto.subtle.importKey(
  #|     "raw",
  #|     encoder.encode(secret),
  #|     { name: "HMAC", hash: "SHA-256" },
  #|     false,
  #|     ["sign"]
  #|   );
  #|   const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(data));
  #|   const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  #|   return data + "." + sigB64;
  #| }

///|
/// Verify JWT token and return payload JSON string if valid.
extern "js" fn jwt_verify_payload_json(
  token : String,
  secret : String,
) -> @core.Promise[String?] =
  #| async (token, secret) => {
  #|   try {
  #|     const b64urlToB64 = (value) => {
  #|       const base64 = value.replace(/-/g, "+").replace(/_/g, "/");
  #|       const pad = base64.length % 4;
  #|       return pad ? base64 + "=".repeat(4 - pad) : base64;
  #|     };
  #|     const parts = token.split(".");
  #|     if (parts.length !== 3) return undefined;
  #|     const [headerB64, payloadB64, sigB64] = parts;
  #|     const encoder = new TextEncoder();
  #|     const key = await crypto.subtle.importKey(
  #|       "raw",
  #|       encoder.encode(secret),
  #|       { name: "HMAC", hash: "SHA-256" },
  #|       false,
  #|       ["verify"]
  #|     );
  #|     const data = headerB64 + "." + payloadB64;
  #|     const sigBytes = Uint8Array.from(atob(b64urlToB64(sigB64)), c => c.charCodeAt(0));
  #|     const sigBuffer = sigBytes.buffer.slice(sigBytes.byteOffset, sigBytes.byteOffset + sigBytes.byteLength);
  #|     const dataBytes = encoder.encode(data);
  #|     const valid = await crypto.subtle.verify("HMAC", key, sigBuffer, dataBytes);
  #|     if (!valid) return undefined;
  #|     return atob(b64urlToB64(payloadB64));
  #|   } catch (e) {
  #|     return undefined;
  #|   }
  #| }

// =============================================================================
// Crypto Utilities
// =============================================================================

///|
/// Generate UUID v4
extern "js" fn generate_uuid() -> String =
  #| () => crypto.randomUUID()

///|
/// Get current Unix timestamp in seconds
extern "js" fn now_unix_seconds() -> Int =
  #| () => Math.floor(Date.now() / 1000)

// =============================================================================
// Cookie Parsing
// =============================================================================

///|
/// Parse cookies from Cookie header and get specific cookie value
extern "js" fn get_cookie_value(
  cookie_header : String,
  name : String,
) -> String? =
  #| (cookieHeader, name) => {
  #|   const cookies = cookieHeader.split(";").map(c => c.trim());
  #|   for (const cookie of cookies) {
  #|     const [key, ...valueParts] = cookie.split("=");
  #|     if (key === name) {
  #|       return valueParts.join("=");
  #|     }
  #|   }
  #|   return undefined;
  #| }

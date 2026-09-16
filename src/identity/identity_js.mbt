///|
extern "js" fn kv_get(kv : @core.Any, key : String) -> @core.Promise[String?] =
  #| async (kv, key) => {
  #|   const value = await kv.get(key, "text");
  #|   return value === null ? undefined : value;
  #| }

///|
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
extern "js" fn kv_delete(kv : @core.Any, key : String) -> @core.Promise[Unit] =
  #| async (kv, key) => {
  #|   await kv.delete(key);
  #| }

///|
extern "js" fn generate_uuid() -> String =
  #| () => crypto.randomUUID()

///|
extern "js" fn now_unix_seconds() -> Int =
  #| () => Math.floor(Date.now() / 1000)

///|
extern "js" fn now_iso() -> String =
  #| () => new Date().toISOString()

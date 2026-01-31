///|
fn get_env_any(env : @cloudflare.CloudflareEnv, key : String) -> @core.Any? {
  let env_js : @core.Any = @core.identity(env)
  let value = env_js[key]
  if @core.typeof_(value) == "undefined" || @core.is_null(value) {
    None
  } else {
    Some(value)
  }
}

///|
fn get_env_string(env : @cloudflare.CloudflareEnv, key : String) -> String? {
  match get_env_any(env, key) {
    Some(value) => {
      let str : String = value.cast()
      if str == "" {
        None
      } else {
        Some(str)
      }
    }
    None => None
  }
}

///|
pub fn get_d1(env : @cloudflare.CloudflareEnv) -> @core.Any? {
  match get_env_any(env, "BLOG_DB") {
    Some(value) => Some(@core.identity(value))
    None => None
  }
}

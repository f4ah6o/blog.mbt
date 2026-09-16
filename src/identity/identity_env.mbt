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
pub fn get_rp_id(env : @cloudflare.CloudflareEnv) -> String? {
  get_env_string(env, "RP_ID")
}

///|
pub fn get_rp_name(env : @cloudflare.CloudflareEnv) -> String? {
  get_env_string(env, "RP_NAME")
}

///|
pub fn get_rp_origin(env : @cloudflare.CloudflareEnv) -> String? {
  get_env_string(env, "RP_ORIGIN")
}

///|
/// OAuth owns a separate credential namespace and user identity. It must not
/// fall back to ADMIN_AUTH or ADMIN_USER_ID.
pub fn get_oauth_auth_kv(env : @cloudflare.CloudflareEnv) -> @core.Any? {
  match get_env_any(env, "OAUTH_AUTH") {
    Some(value) => Some(@core.identity(value))
    None => None
  }
}

///|
pub fn get_oauth_user_id(env : @cloudflare.CloudflareEnv) -> String? {
  get_env_string(env, "OAUTH_USER_ID")
}

///|
pub fn get_oauth_rp_id(env : @cloudflare.CloudflareEnv) -> String? {
  get_env_string(env, "OAUTH_RP_ID")
}

///|
pub fn get_oauth_origin(env : @cloudflare.CloudflareEnv) -> String? {
  get_env_string(env, "OAUTH_RP_ORIGIN")
}

///|
pub fn should_use_secure_cookie(env : @cloudflare.CloudflareEnv) -> Bool {
  match get_rp_origin(env) {
    Some(origin) => origin.has_prefix("https://")
    None => true
  }
}

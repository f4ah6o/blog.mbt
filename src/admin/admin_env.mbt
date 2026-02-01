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

///|
/// Get KV namespace for admin authentication (ADMIN_AUTH binding)
fn get_admin_auth_kv(env : @cloudflare.CloudflareEnv) -> @core.Any? {
  match get_env_any(env, "ADMIN_AUTH") {
    Some(value) => Some(@core.identity(value))
    None => None
  }
}

///|
/// Get admin user ID from environment
fn get_admin_user_id(env : @cloudflare.CloudflareEnv) -> String? {
  get_env_string(env, "ADMIN_USER_ID")
}

///|
/// Get JWT secret from environment
fn get_jwt_secret(env : @cloudflare.CloudflareEnv) -> String? {
  get_env_string(env, "JWT_SECRET")
}

///|
/// Get JWT expiration in seconds (default: 86400 = 24h)
fn get_jwt_expires_in(env : @cloudflare.CloudflareEnv) -> Int {
  match get_env_string(env, "JWT_EXPIRES_IN") {
    Some(s) => {
      let parsed : Result[Int, _] = try? @strconv.parse_int(s)
      match parsed {
        Ok(v) if v > 0 => v
        _ => 86400
      }
    }
    None => 86400
  }
}

///|
/// Get Relying Party ID (domain)
fn get_rp_id(env : @cloudflare.CloudflareEnv) -> String? {
  get_env_string(env, "RP_ID")
}

///|
/// Get Relying Party name
fn get_rp_name(env : @cloudflare.CloudflareEnv) -> String? {
  get_env_string(env, "RP_NAME")
}

///|
/// Get Relying Party origin (e.g., https://example.com)
fn get_rp_origin(env : @cloudflare.CloudflareEnv) -> String? {
  get_env_string(env, "RP_ORIGIN")
}

///|
/// Get admin setup token for registration
fn get_admin_setup_token(env : @cloudflare.CloudflareEnv) -> String? {
  get_env_string(env, "ADMIN_SETUP_TOKEN")
}

///|
/// Determine whether to include Secure flag on cookies.
/// Uses RP_ORIGIN to decide; HTTPS origins get Secure.
fn should_use_secure_cookie(env : @cloudflare.CloudflareEnv) -> Bool {
  match get_rp_origin(env) {
    Some(origin) => origin.has_prefix("https://")
    None => true
  }
}

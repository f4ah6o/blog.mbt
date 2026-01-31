///|
pub fn get_d1(env : @cloudflare.CloudflareEnv) -> @cloudflare.D1Database? {
  let env_js : @core.Any = @core.identity(env)
  let db_js = env_js["BLOG_DB"]
  if @core.typeof_(db_js) == "undefined" {
    None
  } else {
    Some(@core.identity(db_js))
  }
}

///|
pub fn extract_slug(pathname : String) -> String? {
  // "/posts/hello-world" -> Some("hello-world")
  // "/posts" -> None
  // "/posts/" -> None
  let prefix = "/posts/"
  if pathname.has_prefix(prefix) && pathname.length() > prefix.length() {
    // Extract slug by taking characters after "/posts/"
    let chars = pathname.to_array()
    let slug_chars : Array[Char] = []
    for i = prefix.length(); i < chars.length(); i = i + 1 {
      slug_chars.push(chars[i])
    }
    let slug = String::from_array(slug_chars)
    if slug.length() > 0 {
      Some(slug)
    } else {
      None
    }
  } else {
    None
  }
}

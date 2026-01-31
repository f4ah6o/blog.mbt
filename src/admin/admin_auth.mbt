///|
fn parse_basic_auth(header : String) -> (String, String)? {
  let prefix = "Basic "
  if !header.has_prefix(prefix) {
    return None
  }
  let encoded_view = try! header[prefix.length():]
  let decoded = decode_base64(encoded_view.to_string())
  match decoded.find(":") {
    Some(pos) => {
      let user_view = try! decoded[:pos]
      let pass_view = try! decoded[pos + 1:]
      Some((user_view.to_string(), pass_view.to_string()))
    }
    None => None
  }
}

///|
fn require_basic_auth(
  req : @http.Request,
  env : @cloudflare.CloudflareEnv,
) -> Result[Unit, @http.Response] {
  let user_opt = get_env_string(env, "ADMIN_USER")
  let pass_opt = get_env_string(env, "ADMIN_PASS")
  match (user_opt, pass_opt) {
    (Some(user), Some(pass)) =>
      match request_header(req, "Authorization") {
        Some(header) =>
          match parse_basic_auth(header) {
            Some((auth_user, auth_pass)) =>
              if auth_user == user && auth_pass == pass {
                Ok(())
              } else {
                Err(unauthorized_response("Admin"))
              }
            None => Err(unauthorized_response("Admin"))
          }
        None => Err(unauthorized_response("Admin"))
      }
    _ =>
      Err(
        html_response(
          "<!DOCTYPE html><html><body><h1>500 Error</h1><p>Admin auth not configured.</p></body></html>",
          500,
        ),
      )
  }
}

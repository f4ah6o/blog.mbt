///|
fn html_response(body : String, status : Int) -> @http.Response {
  @http.Response::html(body, status)
}

///|
fn redirect_to(location : String) -> @http.Response {
  let headers = @core.new_object()
  headers["Location"] = @core.any(location)
  @http.Response::new(body="", status=303, headers~)
}

///|
fn unauthorized_response(realm : String) -> @http.Response {
  let headers = @core.new_object()
  headers["Content-Type"] = @core.any("text/html; charset=utf-8")
  headers["WWW-Authenticate"] = @core.any(
    "Basic realm=\"" + realm + "\", charset=\"UTF-8\"",
  )
  @http.Response::new(
    body="<!DOCTYPE html><html><body><h1>401 Unauthorized</h1><p>Authentication required.</p></body></html>",
    status=401,
    headers~,
  )
}

///|
fn not_found_response() -> @http.Response {
  html_response(
    "<!DOCTYPE html><html><body><h1>404 Not Found</h1><p>Admin route not found.</p></body></html>",
    404,
  )
}

///|
fn method_not_allowed_response() -> @http.Response {
  html_response(
    "<!DOCTYPE html><html><body><h1>405 Method Not Allowed</h1></body></html>", 405,
  )
}

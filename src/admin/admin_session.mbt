///|
/// Session management for admin authentication.
/// Uses JWT tokens stored in HttpOnly cookies.

// =============================================================================
// Constants
// =============================================================================

///|
/// Clock skew tolerance in seconds (±60s)
let clock_skew_tolerance : Int = 60

///|
/// Cookie name for session
let session_cookie_name : String = "session"

// =============================================================================
// JWT Payload
// =============================================================================

///|
/// JWT payload structure
struct JwtPayload {
  /// Subject (user ID)
  sub : String
  /// Issued at (Unix timestamp)
  iat : Int
  /// Expiration (Unix timestamp)
  exp : Int
  /// JWT ID (unique session identifier)
  jti : String
} derive(Show, ToJson, FromJson)

// =============================================================================
// Cookie Building
// =============================================================================

///|
/// Build session cookie with secure attributes.
/// Cookie attributes:
/// - HttpOnly: Prevents XSS theft
/// - Secure: HTTPS only (required for WebAuthn)
/// - SameSite=Strict: CSRF protection
/// - Path=/admin: Only sent for admin routes
fn build_session_cookie(jwt : String, max_age : Int, secure : Bool) -> String {
  let secure_flag = if secure { "Secure; " } else { "" }
  "session=\{jwt}; Max-Age=\{max_age}; Path=/admin; HttpOnly; \{secure_flag}SameSite=Strict"
}

///|
/// Build logout cookie (expires immediately)
fn build_logout_cookie(secure : Bool) -> String {
  let secure_flag = if secure { "Secure; " } else { "" }
  "session=; Max-Age=0; Path=/admin; HttpOnly; \{secure_flag}SameSite=Strict"
}

// =============================================================================
// JWT Operations
// =============================================================================

///|
/// Create a new JWT session token for the given user.
async fn create_session_token(
  user_id : String,
  secret : String,
  expires_in : Int,
) -> String {
  let now = now_unix_seconds()
  let jti = generate_uuid()
  let payload : JwtPayload = {
    sub: user_id,
    iat: now,
    exp: now + expires_in,
    jti,
  }
  let payload_json = payload.to_json().stringify()
  jwt_sign(payload_json, secret).wait()
}

///|
/// Verify JWT token and return the payload if valid.
/// Checks signature and expiration (with clock skew tolerance).
async fn verify_session_token(token : String, secret : String) -> JwtPayload? {
  let payload_json = jwt_verify_payload_json(token, secret).wait()
  match payload_json {
    None => None
    Some(json_str) => {
      let json_result = try? @json.parse(json_str)
      let json = match json_result {
        Ok(j) => j
        Err(_) => return None
      }
      let payload_result : Result[JwtPayload, _] = try? @json.from_json(json)
      let payload = match payload_result {
        Ok(p) => p
        Err(_) => return None
      }
      let now = now_unix_seconds()
      if now > payload.exp + clock_skew_tolerance {
        return None
      }
      if payload.iat > now + clock_skew_tolerance {
        return None
      }
      Some(payload)
    }
  }
}

// =============================================================================
// Session Validation
// =============================================================================

///|
/// Result of session validation
priv enum SessionResult {
  /// Valid session with user ID
  Valid(String)
  /// No session cookie present
  NoSession
  /// Session is invalid or expired
  Invalid
}

///|
/// Validate session from request cookies.
/// Returns SessionResult indicating the validation status.
async fn validate_session(
  req : @http.Request,
  secret : String,
) -> SessionResult {
  // Get Cookie header
  let cookie_header = request_header(req, "Cookie")
  match cookie_header {
    None => NoSession
    Some(cookies) => {
      // Extract session cookie
      let token = get_cookie_value(cookies, session_cookie_name)
      match token {
        None => NoSession
        Some(t) => {
          if t == "" {
            return NoSession
          }
          // Verify the token (async fn - call directly, no .wait())
          let payload = verify_session_token(t, secret)
          match payload {
            None => Invalid
            Some(p) => Valid(p.sub)
          }
        }
      }
    }
  }
}

// =============================================================================
// Response Helpers
// =============================================================================

///|
/// Create a redirect response that clears the session cookie (logout)
fn redirect_with_logout_cookie(
  location : String,
  secure : Bool,
) -> @http.Response {
  let cookie = build_logout_cookie(secure)
  let headers = @core.new_object()
  headers["Location"] = @core.any(location)
  headers["Set-Cookie"] = @core.any(cookie)
  @http.Response::new(body="", status=302, headers~)
}

///|
/// Create a JSON response
fn json_response(body : String, status : Int) -> @http.Response {
  let headers = @core.new_object()
  headers["Content-Type"] = @core.any("application/json")
  @http.Response::new(body~, status~, headers~)
}

///|
/// Create a JSON response with session cookie
fn json_response_with_session_cookie(
  body : String,
  status : Int,
  jwt : String,
  max_age : Int,
  secure : Bool,
) -> @http.Response {
  let cookie = build_session_cookie(jwt, max_age, secure)
  let headers = @core.new_object()
  headers["Content-Type"] = @core.any("application/json")
  headers["Set-Cookie"] = @core.any(cookie)
  @http.Response::new(body~, status~, headers~)
}

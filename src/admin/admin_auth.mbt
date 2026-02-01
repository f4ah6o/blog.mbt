///|
/// Authentication for admin panel.
/// Uses JWT tokens stored in HttpOnly cookies.

// =============================================================================
// Public Paths (no authentication required)
// =============================================================================

///|
/// Paths that don't require authentication.
/// These are checked by prefix matching.
/// Note: /admin/register requires setup token, handled separately.
let public_path_prefixes : Array[String] = ["/admin/login"]

///|
/// Check if a path is public (no auth required)
fn is_public_path(path : String) -> Bool {
  for prefix in public_path_prefixes {
    if path == prefix || path.has_prefix(prefix + "/") {
      return true
    }
  }
  false
}

// =============================================================================
// Setup Token Validation (for registration)
// =============================================================================

///|
/// Check if a request has a valid setup token in header only.
/// Used for /admin/register/options and /admin/register/verify.
/// Returns true if X-Admin-Setup header matches, false otherwise.
fn has_valid_setup_token_header(
  req : @http.Request,
  env : @cloudflare.CloudflareEnv,
) -> Bool {
  // Get expected token from environment
  let expected = match get_admin_setup_token(env) {
    Some(t) => t
    None => return false // Token not configured = always reject
  }
  //
  // Check header only: X-Admin-Setup
  match request_header(req, "X-Admin-Setup") {
    Some(token) if token == expected => true
    _ => false
  }
}

// =============================================================================
// Authentication Result
// =============================================================================

///|
/// Result of authentication check
pub enum AuthResult {
  /// Authenticated with user ID
  Authenticated(String)
  /// Not authenticated - redirect to login (for HTML requests)
  RedirectToLogin
  /// Not authenticated - return 401 (for API requests)
  Unauthorized
  /// Configuration error
  ConfigError(String)
}

// =============================================================================
// JWT Authentication
// =============================================================================

///|
/// Check JWT authentication for a request.
/// 
/// Returns:
/// - Authenticated(user_id) if valid JWT cookie present
/// - RedirectToLogin if no/invalid JWT and request wants HTML
/// - Unauthorized if no/invalid JWT and request wants JSON
/// - ConfigError if JWT_SECRET is not configured
async fn check_jwt_auth(
  req : @http.Request,
  env : @cloudflare.CloudflareEnv,
) -> AuthResult {
  // Get JWT secret from environment
  let secret = match get_jwt_secret(env) {
    Some(s) => s
    None => return ConfigError("JWT_SECRET is not configured")
  }
  //
  // Validate session from cookie
  let session_result = validate_session(req, secret)
  match session_result {
    Valid(user_id) => Authenticated(user_id)
    NoSession | Invalid =>
      // Determine response type based on Accept header
      if wants_json(req) {
        Unauthorized
      } else {
        RedirectToLogin
      }
  }
}

///|
/// Check if request wants JSON response (API call)
fn wants_json(req : @http.Request) -> Bool {
  match request_header(req, "Accept") {
    Some(accept) => accept.contains("application/json")
    None => false
  }
}

// =============================================================================
// Main Authentication Entry Point
// =============================================================================

///|
/// Require authentication for admin routes.
/// 
/// - Public paths (login, register) are allowed without auth
/// - Protected paths require valid JWT cookie
/// 
/// Returns:
/// - Ok(Some(user_id)) if authenticated
/// - Ok(None) if public path (no auth needed)
/// - Err(response) if auth failed (redirect or 401)
pub async fn require_auth(
  req : @http.Request,
  env : @cloudflare.CloudflareEnv,
  path : String,
) -> Result[String?, @http.Response] {
  // Public paths don't need authentication
  if is_public_path(path) {
    return Ok(None)
  }
  //
  // Check JWT authentication
  let auth_result = check_jwt_auth(req, env)
  match auth_result {
    Authenticated(user_id) => Ok(Some(user_id))
    RedirectToLogin => Err(redirect_to("/admin/login"))
    Unauthorized => Err(json_response("{\"error\":\"Unauthorized\"}", 401))
    ConfigError(msg) =>
      Err(html_response(render_error_page("Configuration Error", msg), 500))
  }
}

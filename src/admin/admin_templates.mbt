///|
fn escape_html(value : String) -> String {
  let sb = StringBuilder::new()
  for ch in value {
    match ch {
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      '"' => sb.write_string("&quot;")
      '\'' => sb.write_string("&#39;")
      _ => sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
fn render_errors(errors : Array[String]) -> String {
  if errors.length() == 0 {
    return ""
  }
  let sb = StringBuilder::new()
  sb.write_string("<div class=\"errors\"><p>Fix the following:</p><ul>")
  for err in errors {
    sb.write_string("<li>")
    sb.write_string(escape_html(err))
    sb.write_string("</li>")
  }
  sb.write_string("</ul></div>")
  sb.to_string()
}

///|
fn admin_layout(title : String, body : String) -> String {
  let full_title = title + " - Admin"
  let sb = StringBuilder::new()
  sb.write_string("<!DOCTYPE html><html><head><meta charset=\"utf-8\">")
  sb.write_string(
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
  )
  sb.write_string("<title>")
  sb.write_string(escape_html(full_title))
  sb.write_string("</title>")
  sb.write_string(
    "<style>body{font-family:ui-sans-serif,system-ui,-apple-system,\"Segoe UI\",sans-serif;margin:0;background:#f6f6f3;color:#1d1d1b;}header{background:#111;color:#fff;padding:16px 24px;}header a{color:#fff;text-decoration:none;font-weight:700;}main{max-width:960px;margin:24px auto;padding:0 24px;}h1{margin:0 0 16px;}table{width:100%;border-collapse:collapse;background:#fff;}th,td{padding:12px;border-bottom:1px solid #e5e5e0;text-align:left;vertical-align:top;}th{background:#f2f2ed;}a{color:#1c5d99;}form.inline{display:inline;}button{padding:6px 12px;border-radius:6px;border:1px solid #ccc;background:#fff;cursor:pointer;}button.primary{background:#111;color:#fff;border-color:#111;}button.danger{background:#d64545;color:#fff;border-color:#d64545;}textarea,input[type=\"text\"]{width:100%;padding:8px;border-radius:6px;border:1px solid #ccc;font-family:inherit;}textarea{min-height:220px;}label{display:block;font-weight:600;margin:12px 0 6px;}nav.breadcrumbs{margin-bottom:16px;}nav.breadcrumbs a{margin-right:8px;}div.actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px;}div.errors{background:#ffecec;border:1px solid #f5b5b5;padding:12px;border-radius:6px;margin-bottom:16px;}span.badge{display:inline-block;padding:2px 8px;border-radius:999px;font-size:12px;background:#eee;}span.badge.published{background:#d6f5d6;}span.badge.draft{background:#f7e1b5;}</style>",
  )
  sb.write_string("</head><body>")
  sb.write_string("<header><a href=\"/admin\">Blog Admin</a></header>")
  sb.write_string("<main>")
  sb.write_string(body)
  sb.write_string("</main></body></html>")
  sb.to_string()
}

///|
fn render_error_page(title : String, message : String) -> String {
  let content = "<h1>" +
    escape_html(title) +
    "</h1><p>" +
    escape_html(message) +
    "</p>"
  admin_layout(title, content)
}

///|
fn render_post_form(
  heading : String,
  action : String,
  submit_label : String,
  title : String,
  slug : String,
  excerpt : String,
  content : String,
  errors : Array[String],
) -> String {
  let title_html = escape_html(title)
  let slug_html = escape_html(slug)
  let excerpt_html = escape_html(excerpt)
  let content_html = escape_html(content)
  let sb = StringBuilder::new()
  sb.write_string("<h1>")
  sb.write_string(escape_html(heading))
  sb.write_string("</h1>")
  sb.write_string(render_errors(errors))
  sb.write_string("<form method=\"post\" action=\"")
  sb.write_string(escape_html(action))
  sb.write_string("\">")
  sb.write_string("<label>Title</label>")
  sb.write_string("<input type=\"text\" name=\"title\" value=\"")
  sb.write_string(title_html)
  sb.write_string("\" required>")
  sb.write_string("<label>Slug</label>")
  sb.write_string("<input type=\"text\" name=\"slug\" value=\"")
  sb.write_string(slug_html)
  sb.write_string("\" required>")
  sb.write_string("<label>Excerpt</label>")
  sb.write_string("<textarea name=\"excerpt\">")
  sb.write_string(excerpt_html)
  sb.write_string("</textarea>")
  sb.write_string("<label>Content</label>")
  sb.write_string("<textarea name=\"content\">")
  sb.write_string(content_html)
  sb.write_string("</textarea>")
  sb.write_string("<div class=\"actions\">")
  sb.write_string("<button class=\"primary\" type=\"submit\">")
  sb.write_string(escape_html(submit_label))
  sb.write_string("</button>")
  sb.write_string("</div>")
  sb.write_string("</form>")
  sb.to_string()
}

///|
fn render_post_list(posts : Array[AdminPost]) -> String {
  let sb = StringBuilder::new()
  sb.write_string(
    "<nav class=\"breadcrumbs\"><a href=\"/admin\">Posts</a></nav>",
  )
  sb.write_string("<div class=\"actions\">")
  sb.write_string(
    "<a href=\"/admin/posts/new\"><button class=\"primary\">New Post</button></a>",
  )
  sb.write_string("</div>")
  sb.write_string("<table><thead><tr>")
  sb.write_string(
    "<th>Title</th><th>Status</th><th>Updated</th><th>Published</th><th>Actions</th>",
  )
  sb.write_string("</tr></thead><tbody>")
  for post in posts {
    let id_str = post.id.to_string()
    let title_html = escape_html(post.title)
    let slug_html = escape_html(post.slug)
    let status_label = post_status_label(post.status)
    let status_class = match post.status {
      Draft => "draft"
      Published => "published"
    }
    let updated_html = escape_html(post.updated_at)
    let published_html = match post.published_at {
      Some(ts) => escape_html(ts)
      None => "-"
    }
    sb.write_string("<tr>")
    sb.write_string("<td><strong>")
    sb.write_string(title_html)
    sb.write_string("</strong><div>")
    sb.write_string(slug_html)
    sb.write_string("</div></td>")
    sb.write_string("<td><span class=\"badge ")
    sb.write_string(status_class)
    sb.write_string("\">")
    sb.write_string(escape_html(status_label))
    sb.write_string("</span></td>")
    sb.write_string("<td>")
    sb.write_string(updated_html)
    sb.write_string("</td>")
    sb.write_string("<td>")
    sb.write_string(published_html)
    sb.write_string("</td>")
    sb.write_string("<td>")
    sb.write_string("<div class=\"actions\">")
    sb.write_string("<a href=\"/admin/posts/")
    sb.write_string(id_str)
    sb.write_string("/edit\"><button>Edit</button></a>")
    sb.write_string("<a href=\"/admin/preview/")
    sb.write_string(id_str)
    sb.write_string("\"><button>Preview</button></a>")
    sb.write_string("<a href=\"/posts/")
    sb.write_string(slug_html)
    sb.write_string("\"><button>Public</button></a>")
    match post.status {
      Draft => {
        sb.write_string(
          "<form class=\"inline\" method=\"post\" action=\"/admin/posts/",
        )
        sb.write_string(id_str)
        sb.write_string("/publish\">")
        sb.write_string(
          "<button class=\"primary\" type=\"submit\">Publish</button></form>",
        )
      }
      Published => {
        sb.write_string(
          "<form class=\"inline\" method=\"post\" action=\"/admin/posts/",
        )
        sb.write_string(id_str)
        sb.write_string("/unpublish\">")
        sb.write_string("<button type=\"submit\">Unpublish</button></form>")
      }
    }
    sb.write_string(
      "<form class=\"inline\" method=\"post\" action=\"/admin/posts/",
    )
    sb.write_string(id_str)
    sb.write_string(
      "/delete\" onsubmit=\"return confirm('Delete this post?')\">",
    )
    sb.write_string(
      "<button class=\"danger\" type=\"submit\">Delete</button></form>",
    )
    sb.write_string("</div>")
    sb.write_string("</td>")
    sb.write_string("</tr>")
  }
  sb.write_string("</tbody></table>")
  admin_layout("Posts", sb.to_string())
}

///|
fn render_post_new(
  title : String,
  slug : String,
  excerpt : String,
  content : String,
  errors : Array[String],
) -> String {
  let form_html = render_post_form(
    "New Post", "/admin/posts", "Create", title, slug, excerpt, content, errors,
  )
  admin_layout("New Post", form_html)
}

///|
fn render_post_edit(post : AdminPost, errors : Array[String]) -> String {
  let id_str = post.id.to_string()
  let form_html = render_post_form(
    "Edit Post",
    "/admin/posts/" + id_str,
    "Save",
    post.title,
    post.slug,
    post.excerpt,
    post.content,
    errors,
  )
  let status_label = post_status_label(post.status)
  let published_html = match post.published_at {
    Some(ts) => escape_html(ts)
    None => "-"
  }
  let sb = StringBuilder::new()
  sb.write_string(
    "<nav class=\"breadcrumbs\"><a href=\"/admin\">Posts</a> / Edit</nav>",
  )
  sb.write_string("<p>Status: <strong>")
  sb.write_string(escape_html(status_label))
  sb.write_string("</strong> | Published: ")
  sb.write_string(published_html)
  sb.write_string("</p>")
  sb.write_string(form_html)
  sb.write_string("<div class=\"actions\">")
  sb.write_string("<a href=\"/admin/preview/")
  sb.write_string(id_str)
  sb.write_string("\"><button>Preview</button></a>")
  match post.status {
    Draft => {
      sb.write_string(
        "<form class=\"inline\" method=\"post\" action=\"/admin/posts/",
      )
      sb.write_string(id_str)
      sb.write_string("/publish\">")
      sb.write_string(
        "<button class=\"primary\" type=\"submit\">Publish</button></form>",
      )
    }
    Published => {
      sb.write_string(
        "<form class=\"inline\" method=\"post\" action=\"/admin/posts/",
      )
      sb.write_string(id_str)
      sb.write_string("/unpublish\">")
      sb.write_string("<button type=\"submit\">Unpublish</button></form>")
    }
  }
  sb.write_string(
    "<form class=\"inline\" method=\"post\" action=\"/admin/posts/",
  )
  sb.write_string(id_str)
  sb.write_string("/delete\" onsubmit=\"return confirm('Delete this post?')\">")
  sb.write_string(
    "<button class=\"danger\" type=\"submit\">Delete</button></form>",
  )
  sb.write_string("</div>")
  admin_layout("Edit Post", sb.to_string())
}

///|
fn render_preview(post : AdminPost) -> String {
  let sb = StringBuilder::new()
  sb.write_string(
    "<nav class=\"breadcrumbs\"><a href=\"/admin\">Posts</a> / Preview</nav>",
  )
  sb.write_string("<article>")
  sb.write_string("<h1>")
  sb.write_string(escape_html(post.title))
  sb.write_string("</h1>")
  sb.write_string("<div class=\"meta\">")
  sb.write_string("Status: ")
  sb.write_string(escape_html(post_status_label(post.status)))
  sb.write_string("</div>")
  sb.write_string("<section>")
  sb.write_string(post.content)
  sb.write_string("</section>")
  sb.write_string("</article>")
  admin_layout("Preview", sb.to_string())
}

// =============================================================================
// Login / Registration Templates
// =============================================================================

///|
/// Layout for login/register pages (no header navigation)
fn auth_layout(title : String, body : String) -> String {
  let full_title = title + " - Admin"
  let sb = StringBuilder::new()
  sb.write_string("<!DOCTYPE html><html><head><meta charset=\"utf-8\">")
  sb.write_string(
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
  )
  sb.write_string("<title>")
  sb.write_string(escape_html(full_title))
  sb.write_string("</title>")
  sb.write_string(
    (
      #|<style>
      #|body{font-family:ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif;margin:0;background:#f6f6f3;color:#1d1d1b;min-height:100vh;display:flex;align-items:center;justify-content:center;}
      #|.auth-container{background:#fff;border-radius:12px;box-shadow:0 4px 24px rgba(0,0,0,0.1);padding:48px;max-width:400px;width:100%;margin:24px;}
      #|h1{margin:0 0 8px;font-size:28px;text-align:center;}
      #|.subtitle{color:#666;text-align:center;margin-bottom:32px;}
      #|.error-box{background:#ffecec;border:1px solid #f5b5b5;padding:12px;border-radius:6px;margin-bottom:16px;color:#c53030;}
      #|.info-box{background:#e8f4fd;border:1px solid #90cdf4;padding:12px;border-radius:6px;margin-bottom:16px;color:#2b6cb0;}
      #|button{width:100%;padding:14px;border-radius:8px;border:none;background:#111;color:#fff;font-size:16px;font-weight:600;cursor:pointer;transition:background 0.2s;}
      #|button:hover{background:#333;}
      #|button:disabled{background:#ccc;cursor:not-allowed;}
      #|.passkey-icon{font-size:48px;text-align:center;margin-bottom:16px;}
      #|.link{text-align:center;margin-top:24px;color:#666;}
      #|.link a{color:#1c5d99;}
      #|#status{margin-top:16px;text-align:center;min-height:24px;}
      #|.spinner{display:inline-block;width:20px;height:20px;border:3px solid #f3f3f3;border-top:3px solid #111;border-radius:50%;animation:spin 1s linear infinite;}
      #|@keyframes spin{0%{transform:rotate(0deg);}100%{transform:rotate(360deg);}}
      #|</style>
    ),
  )
  sb.write_string("</head><body>")
  sb.write_string("<div class=\"auth-container\">")
  sb.write_string(body)
  sb.write_string("</div>")
  sb.write_string("</body></html>")
  sb.to_string()
}

///|
/// Render the login page with WebAuthn support
fn render_login_page(error_message : String?) -> String {
  let sb = StringBuilder::new()
  //
  // Error message if present
  match error_message {
    Some(msg) => {
      sb.write_string("<div class=\"error-box\">")
      sb.write_string(escape_html(msg))
      sb.write_string("</div>")
    }
    None => ()
  }
  //
  // Header
  sb.write_string("<div class=\"passkey-icon\">&#128273;</div>")
  sb.write_string("<h1>Admin Login</h1>")
  sb.write_string("<p class=\"subtitle\">Sign in with your passkey</p>")
  //
  // Login button
  sb.write_string("<button id=\"login-btn\" type=\"button\">")
  sb.write_string("Sign in with Passkey")
  sb.write_string("</button>")
  //
  // Status area
  sb.write_string("<div id=\"status\"></div>")
  //
  // Register link
  sb.write_string("<div class=\"link\">")
  sb.write_string(
    "First time? <a href=\"/admin/register\">Register a passkey</a>",
  )
  sb.write_string("</div>")
  //
  // JavaScript for WebAuthn
  sb.write_string(
    (
      #|<script>
      #|(function() {
      #|  const loginBtn = document.getElementById('login-btn');
      #|  const status = document.getElementById('status');
      #|
      #|  function showStatus(msg, isError) {
      #|    status.innerHTML = isError 
      #|      ? '<span style="color:#c53030">' + msg + '</span>'
      #|      : msg;
      #|  }
      #|
      #|  function showSpinner() {
      #|    status.innerHTML = '<div class="spinner"></div>';
      #|  }
      #|
      #|  // Check WebAuthn support
      #|  if (!window.PublicKeyCredential) {
      #|    loginBtn.disabled = true;
      #|    showStatus('WebAuthn is not supported in this browser', true);
      #|    return;
      #|  }
      #|
      #|  loginBtn.addEventListener('click', async function() {
      #|    loginBtn.disabled = true;
      #|    showSpinner();
      #|
      #|    try {
      #|      // 1. Get authentication options from server
      #|      const optionsRes = await fetch('/admin/login/options', {
      #|        method: 'GET',
      #|        headers: { 'Accept': 'application/json' }
      #|      });
      #|      if (!optionsRes.ok) {
      #|        const err = await optionsRes.json().catch(() => ({}));
      #|        throw new Error(err.error || 'Failed to get login options');
      #|      }
      #|      const options = await optionsRes.json();
      #|
      #|      // 2. Convert base64url to ArrayBuffer
      #|      function base64urlToBuffer(base64url) {
      #|        const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
      #|        const pad = base64.length % 4;
      #|        const padded = pad ? base64 + '='.repeat(4 - pad) : base64;
      #|        const binary = atob(padded);
      #|        const bytes = new Uint8Array(binary.length);
      #|        for (let i = 0; i < binary.length; i++) {
      #|          bytes[i] = binary.charCodeAt(i);
      #|        }
      #|        return bytes.buffer;
      #|      }
      #|
      #|      function bufferToBase64url(buffer) {
      #|        const bytes = new Uint8Array(buffer);
      #|        let binary = '';
      #|        for (let i = 0; i < bytes.length; i++) {
      #|          binary += String.fromCharCode(bytes[i]);
      #|        }
      #|        return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
      #|      }
      #|
      #|      // 3. Build credential request options
      #|      const publicKeyOptions = {
      #|        challenge: base64urlToBuffer(options.challenge),
      #|        timeout: options.timeout,
      #|        rpId: options.rp_id,
      #|        userVerification: options.user_verification || 'preferred'
      #|      };
      #|
      #|      // Add allowCredentials if present
      #|      if (options.allow_credentials && options.allow_credentials.length > 0) {
      #|        publicKeyOptions.allowCredentials = options.allow_credentials.map(c => ({
      #|          id: base64urlToBuffer(c.id),
      #|          type: c.type,
      #|          transports: c.transports || []
      #|        }));
      #|      }
      #|
      #|      // 4. Call WebAuthn API
      #|      showStatus('Touch your authenticator...', false);
      #|      const credential = await navigator.credentials.get({
      #|        publicKey: publicKeyOptions
      #|      });
      #|
      #|      // 5. Send response to server for verification
      #|      showSpinner();
      #|      const verifyRes = await fetch('/admin/login/verify', {
      #|        method: 'POST',
      #|        headers: {
      #|          'Content-Type': 'application/json',
      #|          'Accept': 'application/json'
      #|        },
      #|        body: JSON.stringify({
      #|          challenge_id: options.challenge_id,
      #|          credential_id: bufferToBase64url(credential.rawId),
      #|          raw_id: bufferToBase64url(credential.rawId),
      #|          client_data_json: bufferToBase64url(credential.response.clientDataJSON),
      #|          authenticator_data: bufferToBase64url(credential.response.authenticatorData),
      #|          signature: bufferToBase64url(credential.response.signature)
      #|        })
      #|      });
      #|
      #|      if (!verifyRes.ok) {
      #|        const err = await verifyRes.json().catch(() => ({}));
      #|        throw new Error(err.error || 'Authentication failed');
      #|      }
      #|
      #|      // 6. Success - redirect to admin
      #|      showStatus('Success! Redirecting...', false);
      #|      window.location.href = '/admin';
      #|
      #|    } catch (err) {
      #|      console.error('Login error:', err);
      #|      showStatus(err.message || 'Authentication failed', true);
      #|      loginBtn.disabled = false;
      #|    }
      #|  });
      #|})();
      #|</script>
    ),
  )
  auth_layout("Login", sb.to_string())
}

///|
/// Render the registration page with WebAuthn support
/// Uses form-based token input (no URL query parameter)
fn render_register_page(error_message : String?) -> String {
  let sb = StringBuilder::new()
  //
  // Error message if present
  match error_message {
    Some(msg) => {
      sb.write_string("<div class=\"error-box\">")
      sb.write_string(escape_html(msg))
      sb.write_string("</div>")
    }
    None => ()
  }
  //
  // Header
  sb.write_string("<div class=\"passkey-icon\">&#128273;</div>")
  sb.write_string("<h1>Register Passkey</h1>")
  sb.write_string(
    "<p class=\"subtitle\">Create a passkey for passwordless login</p>",
  )
  //
  // Token input section (shown initially)
  sb.write_string("<div id=\"unlock-section\">")
  sb.write_string("<label for=\"setup-token\" style=\"display:block;margin-bottom:8px;font-weight:600;\">Setup Token</label>")
  sb.write_string("<input type=\"password\" id=\"setup-token\" placeholder=\"Enter setup token\" style=\"width:100%;padding:12px;border-radius:8px;border:1px solid #ccc;margin-bottom:16px;font-size:16px;\">")
  sb.write_string("<button id=\"unlock-btn\" type=\"button\">")
  sb.write_string("Unlock Registration")
  sb.write_string("</button>")
  sb.write_string("</div>")
  //
  // Register section (hidden until unlocked)
  sb.write_string("<div id=\"register-section\" style=\"display:none;\">")
  sb.write_string("<div class=\"info-box\" style=\"background:#d6f5d6;border-color:#68d391;color:#276749;\">")
  sb.write_string("&#10003; Registration unlocked")
  sb.write_string("</div>")
  sb.write_string("<button id=\"register-btn\" type=\"button\">")
  sb.write_string("Register Passkey")
  sb.write_string("</button>")
  sb.write_string("</div>")
  //
  // Status area
  sb.write_string("<div id=\"status\"></div>")
  //
  // Login link
  sb.write_string("<div class=\"link\">")
  sb.write_string("Already registered? <a href=\"/admin/login\">Sign in</a>")
  sb.write_string("</div>")
  //
  // JavaScript for WebAuthn registration with form-based token input
  sb.write_string(
    (
      #|<script>
      #|(function() {
      #|  const STORAGE_KEY = 'admin_setup_token';
      #|  const unlockSection = document.getElementById('unlock-section');
      #|  const registerSection = document.getElementById('register-section');
      #|  const tokenInput = document.getElementById('setup-token');
      #|  const unlockBtn = document.getElementById('unlock-btn');
      #|  const registerBtn = document.getElementById('register-btn');
      #|  const status = document.getElementById('status');
      #|
      #|  function showStatus(msg, isError) {
      #|    status.innerHTML = isError 
      #|      ? '<span style="color:#c53030">' + msg + '</span>'
      #|      : msg;
      #|  }
      #|
      #|  function showSpinner() {
      #|    status.innerHTML = '<div class="spinner"></div>';
      #|  }
      #|
      #|  function clearStatus() {
      #|    status.innerHTML = '';
      #|  }
      #|
      #|  function getToken() {
      #|    return sessionStorage.getItem(STORAGE_KEY);
      #|  }
      #|
      #|  function setToken(token) {
      #|    sessionStorage.setItem(STORAGE_KEY, token);
      #|  }
      #|
      #|  function clearToken() {
      #|    sessionStorage.removeItem(STORAGE_KEY);
      #|  }
      #|
      #|  function showUnlocked() {
      #|    unlockSection.style.display = 'none';
      #|    registerSection.style.display = 'block';
      #|    clearStatus();
      #|  }
      #|
      #|  function showLocked() {
      #|    unlockSection.style.display = 'block';
      #|    registerSection.style.display = 'none';
      #|  }
      #|
      #|  // Check WebAuthn support
      #|  if (!window.PublicKeyCredential) {
      #|    unlockBtn.disabled = true;
      #|    showStatus('WebAuthn is not supported in this browser', true);
      #|    return;
      #|  }
      #|
      #|  // Check for existing token in sessionStorage
      #|  const existingToken = getToken();
      #|  if (existingToken) {
      #|    // Verify token is still valid by calling /options
      #|    showSpinner();
      #|    fetch('/admin/register/options', {
      #|      method: 'GET',
      #|      headers: {
      #|        'Accept': 'application/json',
      #|        'X-Admin-Setup': existingToken
      #|      }
      #|    }).then(res => {
      #|      if (res.ok) {
      #|        showUnlocked();
      #|      } else {
      #|        clearToken();
      #|        showLocked();
      #|        clearStatus();
      #|      }
      #|    }).catch(() => {
      #|      clearToken();
      #|      showLocked();
      #|      clearStatus();
      #|    });
      #|  }
      #|
      #|  // Unlock button handler
      #|  unlockBtn.addEventListener('click', async function() {
      #|    const token = tokenInput.value.trim();
      #|    if (!token) {
      #|      showStatus('Please enter the setup token', true);
      #|      return;
      #|    }
      #|
      #|    unlockBtn.disabled = true;
      #|    showSpinner();
      #|
      #|    try {
      #|      // Verify token by calling /options
      #|      const res = await fetch('/admin/register/options', {
      #|        method: 'GET',
      #|        headers: {
      #|          'Accept': 'application/json',
      #|          'X-Admin-Setup': token
      #|        }
      #|      });
      #|
      #|      if (res.ok) {
      #|        setToken(token);
      #|        showUnlocked();
      #|      } else {
      #|        showStatus('Invalid setup token', true);
      #|        unlockBtn.disabled = false;
      #|      }
      #|    } catch (err) {
      #|      showStatus('Failed to verify token', true);
      #|      unlockBtn.disabled = false;
      #|    }
      #|  });
      #|
      #|  // Allow Enter key in token input
      #|  tokenInput.addEventListener('keypress', function(e) {
      #|    if (e.key === 'Enter') {
      #|      unlockBtn.click();
      #|    }
      #|  });
      #|
      #|  // Register button handler
      #|  registerBtn.addEventListener('click', async function() {
      #|    const token = getToken();
      #|    if (!token) {
      #|      showLocked();
      #|      showStatus('Session expired. Please enter token again.', true);
      #|      return;
      #|    }
      #|
      #|    registerBtn.disabled = true;
      #|    showSpinner();
      #|
      #|    try {
      #|      // 1. Get registration options from server
      #|      const optionsRes = await fetch('/admin/register/options', {
      #|        method: 'GET',
      #|        headers: {
      #|          'Accept': 'application/json',
      #|          'X-Admin-Setup': token
      #|        }
      #|      });
      #|      if (!optionsRes.ok) {
      #|        if (optionsRes.status === 403) {
      #|          clearToken();
      #|          showLocked();
      #|          showStatus('Token expired or invalid. Please enter again.', true);
      #|          return;
      #|        }
      #|        const err = await optionsRes.json().catch(() => ({}));
      #|        throw new Error(err.error || 'Failed to get registration options');
      #|      }
      #|      const options = await optionsRes.json();
      #|
      #|      // 2. Convert base64url to ArrayBuffer
      #|      function base64urlToBuffer(base64url) {
      #|        const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
      #|        const pad = base64.length % 4;
      #|        const padded = pad ? base64 + '='.repeat(4 - pad) : base64;
      #|        const binary = atob(padded);
      #|        const bytes = new Uint8Array(binary.length);
      #|        for (let i = 0; i < binary.length; i++) {
      #|          bytes[i] = binary.charCodeAt(i);
      #|        }
      #|        return bytes.buffer;
      #|      }
      #|
      #|      function bufferToBase64url(buffer) {
      #|        const bytes = new Uint8Array(buffer);
      #|        let binary = '';
      #|        for (let i = 0; i < bytes.length; i++) {
      #|          binary += String.fromCharCode(bytes[i]);
      #|        }
      #|        return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
      #|      }
      #|
      #|      // 3. Build credential creation options
      #|      const publicKeyOptions = {
      #|        challenge: base64urlToBuffer(options.challenge),
      #|        rp: {
      #|          id: options.rp.id,
      #|          name: options.rp.name
      #|        },
      #|        user: {
      #|          id: base64urlToBuffer(options.user.id),
      #|          name: options.user.name,
      #|          displayName: options.user.displayName
      #|        },
      #|        pubKeyCredParams: options.pub_key_cred_params.map(p => ({
      #|          type: p.type,
      #|          alg: p.alg
      #|        })),
      #|        timeout: options.timeout,
      #|        attestation: options.attestation || 'none',
      #|        authenticatorSelection: {
      #|          residentKey: options.authenticator_selection.residentKey,
      #|          userVerification: options.authenticator_selection.userVerification
      #|        }
      #|      };
      #|
      #|      // Add excludeCredentials if present
      #|      if (options.exclude_credentials && options.exclude_credentials.length > 0) {
      #|        publicKeyOptions.excludeCredentials = options.exclude_credentials.map(c => ({
      #|          id: base64urlToBuffer(c.id),
      #|          type: c.type,
      #|          transports: c.transports || []
      #|        }));
      #|      }
      #|
      #|      // 4. Call WebAuthn API
      #|      showStatus('Follow your authenticator prompts...', false);
      #|      const credential = await navigator.credentials.create({
      #|        publicKey: publicKeyOptions
      #|      });
      #|
      #|      // 5. Send response to server for verification
      #|      showSpinner();
      #|      const verifyRes = await fetch('/admin/register/verify', {
      #|        method: 'POST',
      #|        headers: {
      #|          'Content-Type': 'application/json',
      #|          'Accept': 'application/json',
      #|          'X-Admin-Setup': token
      #|        },
      #|        body: JSON.stringify({
      #|          challenge_id: options.challenge_id,
      #|          credential_id: bufferToBase64url(credential.rawId),
      #|          raw_id: bufferToBase64url(credential.rawId),
      #|          client_data_json: bufferToBase64url(credential.response.clientDataJSON),
      #|          attestation_object: bufferToBase64url(credential.response.attestationObject)
      #|        })
      #|      });
      #|
      #|      if (!verifyRes.ok) {
      #|        if (verifyRes.status === 403) {
      #|          clearToken();
      #|          showLocked();
      #|          showStatus('Token expired or invalid. Please enter again.', true);
      #|          return;
      #|        }
      #|        const err = await verifyRes.json().catch(() => ({}));
      #|        throw new Error(err.error || 'Registration failed');
      #|      }
      #|
      #|      // 6. Success - clear token and redirect to login
      #|      clearToken();
      #|      showStatus('Passkey registered! Redirecting to login...', false);
      #|      setTimeout(() => {
      #|        window.location.href = '/admin/login';
      #|      }, 1500);
      #|
      #|    } catch (err) {
      #|      console.error('Registration error:', err);
      #|      showStatus(err.message || 'Registration failed', true);
      #|      registerBtn.disabled = false;
      #|    }
      #|  });
      #|})();
      #|</script>
    ),
  )
  auth_layout("Register", sb.to_string())
}

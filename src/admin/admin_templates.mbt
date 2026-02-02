///|
fn render_errors(errors : Array[String]) -> @tmpx.Node {
  if errors.length() == 0 {
    return @tmpx.fragment([])
  }
  let items : Array[@tmpx.Node] = []
  for err in errors {
    items.push(@tmpx.li([], [@tmpx.text(err)]))
  }
  @tmpx.div([@tmpx.class_("errors")], [
    @tmpx.p([], [@tmpx.text("Fix the following:")]),
    @tmpx.ul([], items),
  ])
}

///|
fn admin_layout(title : String, body : @tmpx.Node) -> String {
  let full_title = title + " - Admin"
  let doc = @tmpx.fragment([
    @tmpx.raw_html("<!DOCTYPE html>"),
    @tmpx.html_([], [
      @tmpx.head([], [
        @tmpx.meta([@tmpx.charset("utf-8")]),
        @tmpx.meta([
          @tmpx.name_("viewport"),
          @tmpx.content("width=device-width, initial-scale=1"),
        ]),
        @tmpx.title([], [@tmpx.text(full_title)]),
        @tmpx.raw_html(
          "<style>body{font-family:ui-sans-serif,system-ui,-apple-system,\"Segoe UI\",sans-serif;margin:0;background:#f6f6f3;color:#1d1d1b;}header{background:#111;color:#fff;padding:16px 24px;}header a{color:#fff;text-decoration:none;font-weight:700;}main{max-width:960px;margin:24px auto;padding:0 24px;}h1{margin:0 0 16px;}table{width:100%;border-collapse:collapse;background:#fff;}th,td{padding:12px;border-bottom:1px solid #e5e5e0;text-align:left;vertical-align:top;}th{background:#f2f2ed;}a{color:#1c5d99;}form.inline{display:inline;}button{padding:6px 12px;border-radius:6px;border:1px solid #ccc;background:#fff;cursor:pointer;}button.primary{background:#111;color:#fff;border-color:#111;}button.danger{background:#d64545;color:#fff;border-color:#d64545;}textarea,input[type=\"text\"]{width:100%;padding:8px;border-radius:6px;border:1px solid #ccc;font-family:inherit;}textarea{min-height:220px;}label{display:block;font-weight:600;margin:12px 0 6px;}nav.breadcrumbs{margin-bottom:16px;}nav.breadcrumbs a{margin-right:8px;}div.actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px;}div.errors{background:#ffecec;border:1px solid #f5b5b5;padding:12px;border-radius:6px;margin-bottom:16px;}span.badge{display:inline-block;padding:2px 8px;border-radius:999px;font-size:12px;background:#eee;}span.badge.published{background:#d6f5d6;}span.badge.draft{background:#f7e1b5;}</style>",
        ),
      ]),
      @tmpx.body([], [
        @tmpx.header_([], [
          @tmpx.a([@tmpx.href("/admin")], [@tmpx.text("Blog Admin")]),
        ]),
        @tmpx.main_([], [body]),
      ]),
    ]),
  ])
  @tmpx.render(doc)
}

///|
fn render_error_page(title : String, message : String) -> String {
  admin_layout(
    title,
    @tmpx.fragment([
      @tmpx.h1([], [@tmpx.text(title)]),
      @tmpx.p([], [@tmpx.text(message)]),
    ]),
  )
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
) -> @tmpx.Node {
  @tmpx.fragment([
    @tmpx.h1([], [@tmpx.text(heading)]),
    render_errors(errors),
    @tmpx.form([@tmpx.method_("post"), @tmpx.action(action)], [
      @tmpx.label([], [@tmpx.text("Title")]),
      @tmpx.input_([
        @tmpx.type_("text"),
        @tmpx.name_("title"),
        @tmpx.value_(title),
        @tmpx.bool_attr("required"),
      ]),
      @tmpx.label([], [@tmpx.text("Slug")]),
      @tmpx.input_([
        @tmpx.type_("text"),
        @tmpx.name_("slug"),
        @tmpx.value_(slug),
        @tmpx.bool_attr("required"),
      ]),
      @tmpx.label([], [@tmpx.text("Excerpt")]),
      @tmpx.textarea([@tmpx.name_("excerpt")], [@tmpx.text(excerpt)]),
      @tmpx.label([], [@tmpx.text("Content")]),
      @tmpx.textarea([@tmpx.name_("content")], [@tmpx.text(content)]),
      @tmpx.div([@tmpx.class_("actions")], [
        @tmpx.button([@tmpx.class_("primary"), @tmpx.type_("submit")], [
          @tmpx.text(submit_label),
        ]),
      ]),
    ]),
  ])
}

///|
fn render_post_list(posts : Array[AdminPost]) -> String {
  let rows : Array[@tmpx.Node] = []
  for post in posts {
    let id_str = post.id.to_string()
    let status_label = post_status_label(post.status)
    let status_class = match post.status {
      Draft => "draft"
      Published => "published"
    }
    let published_label = match post.published_at {
      Some(ts) => ts
      None => "-"
    }
    rows.push(
      @tmpx.tr([], [
        @tmpx.td([], [
          @tmpx.strong([], [@tmpx.text(post.title)]),
          @tmpx.div([], [@tmpx.text(post.slug)]),
        ]),
        @tmpx.td([], [
          @tmpx.span([@tmpx.class_("badge " + status_class)], [
            @tmpx.text(status_label),
          ]),
        ]),
        @tmpx.td([], [@tmpx.text(post.updated_at)]),
        @tmpx.td([], [@tmpx.text(published_label)]),
        @tmpx.td([], [
          @tmpx.div([@tmpx.class_("actions")], [
            @tmpx.a([@tmpx.href("/admin/posts/" + id_str + "/edit")], [
              @tmpx.button([], [@tmpx.text("Edit")]),
            ]),
            @tmpx.a([@tmpx.href("/admin/preview/" + id_str)], [
              @tmpx.button([], [@tmpx.text("Preview")]),
            ]),
            @tmpx.a([@tmpx.href("/posts/" + post.slug)], [
              @tmpx.button([], [@tmpx.text("Public")]),
            ]),
            match post.status {
              Draft =>
                @tmpx.form(
                  [
                    @tmpx.class_("inline"),
                    @tmpx.method_("post"),
                    @tmpx.action("/admin/posts/" + id_str + "/publish"),
                  ],
                  [
                    @tmpx.button(
                      [@tmpx.class_("primary"), @tmpx.type_("submit")],
                      [@tmpx.text("Publish")],
                    ),
                  ],
                )
              Published =>
                @tmpx.form(
                  [
                    @tmpx.class_("inline"),
                    @tmpx.method_("post"),
                    @tmpx.action("/admin/posts/" + id_str + "/unpublish"),
                  ],
                  [
                    @tmpx.button([@tmpx.type_("submit")], [
                      @tmpx.text("Unpublish"),
                    ]),
                  ],
                )
            },
            @tmpx.form(
              [
                @tmpx.class_("inline"),
                @tmpx.method_("post"),
                @tmpx.action("/admin/posts/" + id_str + "/delete"),
                @tmpx.attr("onsubmit", "return confirm('Delete this post?')"),
              ],
              [
                @tmpx.button([@tmpx.class_("danger"), @tmpx.type_("submit")], [
                  @tmpx.text("Delete"),
                ]),
              ],
            ),
          ]),
        ]),
      ]),
    )
  }
  admin_layout(
    "Posts",
    @tmpx.fragment([
      @tmpx.nav([@tmpx.class_("breadcrumbs")], [
        @tmpx.a([@tmpx.href("/admin")], [@tmpx.text("Posts")]),
      ]),
      @tmpx.div([@tmpx.class_("actions")], [
        @tmpx.a([@tmpx.href("/admin/posts/new")], [
          @tmpx.button([@tmpx.class_("primary")], [@tmpx.text("New Post")]),
        ]),
      ]),
      @tmpx.table([], [
        @tmpx.thead([], [
          @tmpx.tr([], [
            @tmpx.th([], [@tmpx.text("Title")]),
            @tmpx.th([], [@tmpx.text("Status")]),
            @tmpx.th([], [@tmpx.text("Updated")]),
            @tmpx.th([], [@tmpx.text("Published")]),
            @tmpx.th([], [@tmpx.text("Actions")]),
          ]),
        ]),
        @tmpx.tbody([], rows),
      ]),
    ]),
  )
}

///|
fn render_post_new(
  title : String,
  slug : String,
  excerpt : String,
  content : String,
  errors : Array[String],
) -> String {
  admin_layout(
    "New Post",
    render_post_form(
      "New Post", "/admin/posts", "Create", title, slug, excerpt, content, errors,
    ),
  )
}

///|
fn render_post_edit(post : AdminPost, errors : Array[String]) -> String {
  let id_str = post.id.to_string()
  let status_label = post_status_label(post.status)
  let published_label = match post.published_at {
    Some(ts) => ts
    None => "-"
  }
  admin_layout(
    "Edit Post",
    @tmpx.fragment([
      @tmpx.nav([@tmpx.class_("breadcrumbs")], [
        @tmpx.a([@tmpx.href("/admin")], [@tmpx.text("Posts")]),
        @tmpx.text(" / Edit"),
      ]),
      @tmpx.p([], [
        @tmpx.text("Status: "),
        @tmpx.strong([], [@tmpx.text(status_label)]),
        @tmpx.text(" | Published: "),
        @tmpx.text(published_label),
      ]),
      render_post_form(
        "Edit Post",
        "/admin/posts/" + id_str,
        "Save",
        post.title,
        post.slug,
        post.excerpt,
        post.content,
        errors,
      ),
      @tmpx.div([@tmpx.class_("actions")], [
        @tmpx.a([@tmpx.href("/admin/preview/" + id_str)], [
          @tmpx.button([], [@tmpx.text("Preview")]),
        ]),
        match post.status {
          Draft =>
            @tmpx.form(
              [
                @tmpx.class_("inline"),
                @tmpx.method_("post"),
                @tmpx.action("/admin/posts/" + id_str + "/publish"),
              ],
              [
                @tmpx.button([@tmpx.class_("primary"), @tmpx.type_("submit")], [
                  @tmpx.text("Publish"),
                ]),
              ],
            )
          Published =>
            @tmpx.form(
              [
                @tmpx.class_("inline"),
                @tmpx.method_("post"),
                @tmpx.action("/admin/posts/" + id_str + "/unpublish"),
              ],
              [@tmpx.button([@tmpx.type_("submit")], [@tmpx.text("Unpublish")])],
            )
        },
        @tmpx.form(
          [
            @tmpx.class_("inline"),
            @tmpx.method_("post"),
            @tmpx.action("/admin/posts/" + id_str + "/delete"),
            @tmpx.attr("onsubmit", "return confirm('Delete this post?')"),
          ],
          [
            @tmpx.button([@tmpx.class_("danger"), @tmpx.type_("submit")], [
              @tmpx.text("Delete"),
            ]),
          ],
        ),
      ]),
    ]),
  )
}

///|
fn render_preview(post : AdminPost) -> String {
  admin_layout(
    "Preview",
    @tmpx.fragment([
      @tmpx.nav([@tmpx.class_("breadcrumbs")], [
        @tmpx.a([@tmpx.href("/admin")], [@tmpx.text("Posts")]),
        @tmpx.text(" / Preview"),
      ]),
      @tmpx.article([], [
        @tmpx.h1([], [@tmpx.text(post.title)]),
        @tmpx.div([@tmpx.class_("meta")], [
          @tmpx.text("Status: "),
          @tmpx.text(post_status_label(post.status)),
        ]),
        @tmpx.section([], [@tmpx.raw_html(post.content)]),
      ]),
    ]),
  )
}

// =============================================================================
// Login / Registration Templates
// =============================================================================

///|
/// Layout for login/register pages (no header navigation)
fn auth_layout(title : String, body : @tmpx.Node) -> String {
  let full_title = title + " - Admin"
  let doc = @tmpx.fragment([
    @tmpx.raw_html("<!DOCTYPE html>"),
    @tmpx.html_([], [
      @tmpx.head([], [
        @tmpx.meta([@tmpx.charset("utf-8")]),
        @tmpx.meta([
          @tmpx.name_("viewport"),
          @tmpx.content("width=device-width, initial-scale=1"),
        ]),
        @tmpx.title([], [@tmpx.text(full_title)]),
        @tmpx.raw_html(
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
        ),
      ]),
      @tmpx.body([], [@tmpx.div([@tmpx.class_("auth-container")], [body])]),
    ]),
  ])
  @tmpx.render(doc)
}

///|
/// Render the login page with WebAuthn support
fn render_login_page(error_message : String?) -> String {
  let nodes : Array[@tmpx.Node] = []
  match error_message {
    Some(msg) =>
      nodes.push(@tmpx.div([@tmpx.class_("error-box")], [@tmpx.text(msg)]))
    None => ()
  }
  nodes.push(
    @tmpx.div([@tmpx.class_("passkey-icon")], [@tmpx.raw_html("&#128273;")]),
  )
  nodes.push(@tmpx.h1([], [@tmpx.text("Admin Login")]))
  nodes.push(
    @tmpx.p([@tmpx.class_("subtitle")], [
      @tmpx.text("Sign in with your passkey"),
    ]),
  )
  nodes.push(
    @tmpx.button([@tmpx.id_("login-btn"), @tmpx.type_("button")], [
      @tmpx.text("Sign in with Passkey"),
    ]),
  )
  nodes.push(@tmpx.div([@tmpx.id_("status")], []))
  nodes.push(
    @tmpx.div([@tmpx.class_("link")], [
      @tmpx.text("First time? "),
      @tmpx.a([@tmpx.href("/admin/register")], [
        @tmpx.text("Register a passkey"),
      ]),
    ]),
  )
  nodes.push(
    @tmpx.raw_html(
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
    ),
  )
  auth_layout("Login", @tmpx.fragment(nodes))
}

///|
/// Render the registration page with WebAuthn support
/// Uses form-based token input (no URL query parameter)
fn render_register_page(error_message : String?) -> String {
  let nodes : Array[@tmpx.Node] = []
  match error_message {
    Some(msg) =>
      nodes.push(@tmpx.div([@tmpx.class_("error-box")], [@tmpx.text(msg)]))
    None => ()
  }
  nodes.push(
    @tmpx.div([@tmpx.class_("passkey-icon")], [@tmpx.raw_html("&#128273;")]),
  )
  nodes.push(@tmpx.h1([], [@tmpx.text("Register Passkey")]))
  nodes.push(
    @tmpx.p([@tmpx.class_("subtitle")], [
      @tmpx.text("Create a passkey for passwordless login"),
    ]),
  )
  nodes.push(
    @tmpx.div([@tmpx.id_("unlock-section")], [
      @tmpx.label(
        [
          @tmpx.for_("setup-token"),
          @tmpx.attr(
            "style", "display:block;margin-bottom:8px;font-weight:600;",
          ),
        ],
        [@tmpx.text("Setup Token")],
      ),
      @tmpx.input_([
        @tmpx.type_("password"),
        @tmpx.id_("setup-token"),
        @tmpx.placeholder("Enter setup token"),
        @tmpx.attr(
          "style", "width:100%;padding:12px;border-radius:8px;border:1px solid #ccc;margin-bottom:16px;font-size:16px;",
        ),
      ]),
      @tmpx.button([@tmpx.id_("unlock-btn"), @tmpx.type_("button")], [
        @tmpx.text("Unlock Registration"),
      ]),
    ]),
  )
  nodes.push(
    @tmpx.div(
      [@tmpx.id_("register-section"), @tmpx.attr("style", "display:none;")],
      [
        @tmpx.div(
          [
            @tmpx.class_("info-box"),
            @tmpx.attr(
              "style", "background:#d6f5d6;border-color:#68d391;color:#276749;",
            ),
          ],
          [@tmpx.raw_html("&#10003; Registration unlocked")],
        ),
        @tmpx.button([@tmpx.id_("register-btn"), @tmpx.type_("button")], [
          @tmpx.text("Register Passkey"),
        ]),
      ],
    ),
  )
  nodes.push(@tmpx.div([@tmpx.id_("status")], []))
  nodes.push(
    @tmpx.div([@tmpx.class_("link")], [
      @tmpx.text("Already registered? "),
      @tmpx.a([@tmpx.href("/admin/login")], [@tmpx.text("Sign in")]),
    ]),
  )
  nodes.push(
    @tmpx.raw_html(
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
    ),
  )
  auth_layout("Register", @tmpx.fragment(nodes))
}

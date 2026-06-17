///|
pub fn render_markdown(content : String) -> @tmpx.Node {
  @papyr_content.render_markdown(content)
}

///|
pub fn render_markdown_with_embeds(
  content : String,
  embed_data : @hashmap.HashMap[String, EmbedData],
) -> @tmpx.Node {
  @papyr_content.render_markdown_with_embeds(content, embed_data)
}

///|
pub fn extract_embed_urls(content : String) -> Array[String] {
  @papyr_content.extract_embed_urls(content)
}

///|
pub fn extract_og_image_url(content : String) -> String? {
  let lines = content.split("\n")
  let mut in_fence = false
  for line_view in lines {
    let line = line_view.to_owned()
    if is_fence_line(line) {
      in_fence = !in_fence
      continue
    }
    if in_fence {
      continue
    }
    match extract_image_from_line(line) {
      Some(url) => return Some(url)
      None => ()
    }
  }
  None
}

///|
fn is_fence_line(line : String) -> Bool {
  line.trim_start().has_prefix("```"[:])
}

///|
fn extract_image_from_line(line : String) -> String? {
  let mut rest = line.view()
  while true {
    match rest.find("!["[:]) {
      Some(start) => {
        let candidate = rest[start:]
        match parse_markdown_image_url(candidate) {
          Some(url) => return Some(url)
          None => rest = candidate[2:]
        }
      }
      None => return None
    }
  }
  None
}

///|
fn parse_markdown_image_url(rest : StringView) -> String? {
  if !rest.has_prefix("!["[:]) {
    return None
  }
  let tail = rest[2:]
  match tail.find("]"[:]) {
    Some(close_alt) => {
      let after_alt = tail[close_alt + 1:]
      if !after_alt.has_prefix("("[:]) {
        return None
      }
      let url_tail = after_alt[1:]
      match url_tail.find(")"[:]) {
        Some(close_url) =>
          sanitize_og_image_url(url_tail[:close_url].to_owned())
        None => None
      }
    }
    None => None
  }
}

///|
fn sanitize_og_image_url(url : String) -> String? {
  let trimmed = url.trim().to_owned()
  if trimmed.is_empty() {
    return None
  }
  if !(trimmed.has_prefix("http://"[:]) ||
    trimmed.has_prefix("https://"[:]) ||
    trimmed.has_prefix("/"[:])) {
    return None
  }
  if is_badge_image_url(trimmed) {
    None
  } else {
    Some(trimmed)
  }
}

///|
fn is_badge_image_url(url : String) -> Bool {
  let lower = url.to_lower()
  lower.contains("img.shields.io"[:]) ||
  lower.contains("shields.io"[:]) ||
  lower.contains("/badge.svg"[:]) ||
  lower.contains("badge.svg?"[:]) ||
  lower.contains("/actions/workflows/"[:])
}

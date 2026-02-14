///|
priv enum ListKind {
  Unordered
  Ordered
} derive(Eq)

///|
pub fn render_markdown(content : String) -> @tmpx.Node {
  render_markdown_with_embeds(content, @hashmap.new())
}

///|
pub fn render_markdown_with_embeds(
  content : String,
  embed_data : @hashmap.HashMap[String, EmbedData],
) -> @tmpx.Node {
  let nodes = render_blocks_with_embeds(content, embed_data)
  @tmpx.fragment(nodes)
}

///|
/// Extract all card and embed URLs from markdown content
pub fn extract_embed_urls(content : String) -> Array[String] {
  let urls : Array[String] = []
  let lines = split_lines(content)
  for line in lines {
    match parse_card_block(line) {
      Some(url) => urls.push(url)
      None => ()
    }
    match parse_embed_block(line) {
      Some(url) => urls.push(url)
      None => ()
    }
  }
  urls
}

///|
fn render_blocks_with_embeds(
  content : String,
  embed_data : @hashmap.HashMap[String, EmbedData],
) -> Array[@tmpx.Node] {
  let lines = split_lines(content)
  let nodes : Array[@tmpx.Node] = []
  let mut i = 0
  let len = lines.length()
  while i < len {
    let line = lines[i]
    if is_blank(line) {
      i = i + 1
      continue
    }
    if is_fence(line) {
      let (code, next_i) = consume_fence(lines, i)
      nodes.push(render_code_block(code))
      i = next_i
      continue
    }
    // Check for [!card](url) or [!embed](url) block-level syntax
    match parse_card_block(line) {
      Some(url) => {
        let node = match embed_data.get(url) {
          Some(CardData(card)) => render_link_card(card)
          _ => render_link_card(LinkCard::default(url))
        }
        nodes.push(node)
        i = i + 1
        continue
      }
      None => ()
    }
    match parse_embed_block(line) {
      Some(url) => {
        let node = match detect_embed_type(url) {
          YouTube(video_id) => render_youtube_embed(video_id)
          Slide(embed_url) => render_embed(Slide(embed_url), url)
          Unknown =>
            match embed_data.get(url) {
              Some(YouTubeId(video_id)) => render_youtube_embed(video_id)
              Some(CardData(card)) => render_link_card(card)
              None => render_embed(Unknown, url)
            }
        }
        nodes.push(node)
        i = i + 1
        continue
      }
      None => ()
    }
    match parse_heading(line) {
      Some((level, text)) => {
        nodes.push(render_heading(level, text))
        i = i + 1
        continue
      }
      None => ()
    }
    match parse_list_item(line) {
      Some((kind, _)) => {
        let (items, next_i) = consume_list(lines, i, kind)
        nodes.push(render_list(kind, items))
        i = next_i
        continue
      }
      None => ()
    }
    let (paragraph, next_i) = consume_paragraph(lines, i)
    if paragraph.length() > 0 {
      nodes.push(render_paragraph(paragraph))
    }
    i = next_i
  }
  nodes
}

///|
fn split_lines(content : String) -> Array[String] {
  let lines : Array[String] = []
  for line_view in content.split("\n") {
    lines.push(line_view.to_string())
  }
  lines
}

///|
fn is_blank(line : String) -> Bool {
  line.trim().length() == 0
}

///|
fn is_fence(line : String) -> Bool {
  line.trim().has_prefix("```"[:])
}

///|
fn parse_heading(line : String) -> (Int, String)? {
  let trimmed_view = line.trim()
  if !trimmed_view.has_prefix("#"[:]) {
    return None
  }
  let trimmed = trimmed_view.to_string()
  let mut level = 0
  for ch in trimmed {
    if ch == '#' {
      level = level + 1
    } else {
      break
    }
  }
  if level == 0 || level > 6 {
    return None
  }
  let rest_view = try! trimmed[level:]
  let rest = rest_view.trim().to_string()
  if rest.length() == 0 {
    None
  } else {
    Some((level, rest))
  }
}

///|
fn parse_list_item(line : String) -> (ListKind, String)? {
  let trimmed_view = line.trim()
  let trimmed = trimmed_view.to_string()
  if trimmed.has_prefix("- "[:]) ||
    trimmed.has_prefix("* "[:]) ||
    trimmed.has_prefix("+ "[:]) {
    let rest_view = try! trimmed[2:]
    return Some((Unordered, rest_view.to_string()))
  }
  match trimmed.find(". "[:]) {
    Some(pos) if pos > 0 => {
      let prefix_view = try! trimmed[:pos]
      if all_digits(prefix_view) {
        let rest_view = try! trimmed[pos + 2:]
        Some((Ordered, rest_view.to_string()))
      } else {
        None
      }
    }
    _ => None
  }
}

///|
fn all_digits(view : StringView) -> Bool {
  if view.length() == 0 {
    return false
  }
  for ch in view {
    if ch < '0' || ch > '9' {
      return false
    }
  }
  true
}

///|
fn consume_fence(lines : Array[String], start : Int) -> (String, Int) {
  let code_lines : Array[String] = []
  let mut i = start + 1
  let len = lines.length()
  while i < len {
    let line = lines[i]
    if is_fence(line) {
      return (join_with_newline(code_lines), i + 1)
    }
    code_lines.push(line)
    i = i + 1
  }
  (join_with_newline(code_lines), len)
}

///|
fn consume_list(
  lines : Array[String],
  start : Int,
  kind : ListKind,
) -> (Array[@tmpx.Node], Int) {
  let items : Array[@tmpx.Node] = []
  let len = lines.length()
  let mut i = start
  while i < len {
    let line = lines[i]
    if is_blank(line) {
      return (items, i)
    }
    match parse_list_item(line) {
      Some((item_kind, text)) if item_kind == kind => {
        items.push(@tmpx.li([], render_inlines(text)))
        i = i + 1
      }
      _ => return (items, i)
    }
  }
  (items, len)
}

///|
fn consume_paragraph(lines : Array[String], start : Int) -> (String, Int) {
  let parts : Array[String] = []
  let len = lines.length()
  let mut i = start
  while i < len {
    let line = lines[i]
    if is_blank(line) {
      break
    }
    if i != start && is_block_start(line) {
      break
    }
    parts.push(line.trim().to_string())
    i = i + 1
  }
  (join_with_space(parts), i)
}

///|
fn is_block_start(line : String) -> Bool {
  is_fence(line) ||
  parse_heading(line) is Some(_) ||
  parse_list_item(line) is Some(_) ||
  parse_card_block(line) is Some(_) ||
  parse_embed_block(line) is Some(_)
}

///|
fn parse_card_block(line : String) -> String? {
  let trimmed = line.trim().to_string()
  // Match [!card](url)
  if !trimmed.has_prefix("[!card]("[:]) {
    return None
  }
  if !trimmed.has_suffix(")"[:]) {
    return None
  }
  // Extract URL between [!card]( and )
  let start = 8 // length of "[!card]("
  let end = trimmed.length() - 1
  if end <= start {
    return None
  }
  let url_view = try! trimmed[start:end]
  let url = url_view.to_string()
  sanitize_link(url)
}

///|
fn parse_embed_block(line : String) -> String? {
  let trimmed = line.trim().to_string()
  // Match [!embed](url)
  if !trimmed.has_prefix("[!embed]("[:]) {
    return None
  }
  if !trimmed.has_suffix(")"[:]) {
    return None
  }
  // Extract URL between [!embed]( and )
  let start = 9 // length of "[!embed]("
  let end = trimmed.length() - 1
  if end <= start {
    return None
  }
  let url_view = try! trimmed[start:end]
  let url = url_view.to_string()
  sanitize_link(url)
}

///|
fn join_with_space(parts : Array[String]) -> String {
  let sb = StringBuilder::new()
  let mut first = true
  for part in parts {
    if part.length() == 0 {
      continue
    }
    if !first {
      sb.write_char(' ')
    }
    sb.write_string(part)
    first = false
  }
  sb.to_string()
}

///|
fn join_with_newline(parts : Array[String]) -> String {
  let sb = StringBuilder::new()
  let mut first = true
  for part in parts {
    if !first {
      sb.write_char('\n')
    }
    sb.write_string(part)
    first = false
  }
  sb.to_string()
}

///|
fn render_heading(level : Int, text : String) -> @tmpx.Node {
  let children = render_inlines(text)
  match level {
    1 => @tmpx.h1([], children)
    2 => @tmpx.h2([], children)
    3 => @tmpx.h3([], children)
    4 => @tmpx.h4([], children)
    5 => @tmpx.h5([], children)
    _ => @tmpx.h6([], children)
  }
}

///|
fn render_list(kind : ListKind, items : Array[@tmpx.Node]) -> @tmpx.Node {
  match kind {
    Unordered => @tmpx.ul([], items)
    Ordered => @tmpx.ol([], items)
  }
}

///|
fn render_paragraph(text : String) -> @tmpx.Node {
  @tmpx.p([], render_inlines(text))
}

///|
fn render_code_block(code : String) -> @tmpx.Node {
  @tmpx.pre([], [@tmpx.code([], [@tmpx.text(code)])])
}

///|
fn render_inlines(text : String) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  let mut rest = text[:]
  while rest.length() > 0 {
    if rest.has_prefix("**"[:]) {
      match parse_strong(rest) {
        Some((node, next_view)) => {
          nodes.push(node)
          rest = next_view
          continue
        }
        None => {
          nodes.push(@tmpx.text("*"))
          rest = try! rest[1:]
          continue
        }
      }
    }
    if rest.has_prefix("*"[:]) {
      match parse_em(rest) {
        Some((node, next_view)) => {
          nodes.push(node)
          rest = next_view
          continue
        }
        None => {
          nodes.push(@tmpx.text("*"))
          rest = try! rest[1:]
          continue
        }
      }
    }
    if rest.has_prefix("`"[:]) {
      match parse_code_span(rest) {
        Some((node, next_view)) => {
          nodes.push(node)
          rest = next_view
          continue
        }
        None => {
          nodes.push(@tmpx.text("`"))
          rest = try! rest[1:]
          continue
        }
      }
    }
    if rest.has_prefix("!["[:]) {
      match parse_image(rest) {
        Some((node, next_view)) => {
          nodes.push(node)
          rest = next_view
          continue
        }
        None => {
          nodes.push(@tmpx.text("!"))
          rest = try! rest[1:]
          continue
        }
      }
    }
    if rest.has_prefix("["[:]) {
      match parse_link(rest) {
        Some((node, next_view)) => {
          nodes.push(node)
          rest = next_view
          continue
        }
        None => {
          nodes.push(@tmpx.text("["))
          rest = try! rest[1:]
          continue
        }
      }
    }
    match find_next_special(rest) {
      Some(pos) if pos > 0 => {
        let chunk_view = try! rest[:pos]
        nodes.push(@tmpx.text(chunk_view.to_string()))
        rest = try! rest[pos:]
      }
      _ => {
        nodes.push(@tmpx.text(rest.to_string()))
        break
      }
    }
  }
  nodes
}

///|
fn parse_strong(rest : StringView) -> (@tmpx.Node, StringView)? {
  if !rest.has_prefix("**"[:]) {
    return None
  }
  let tail = try! rest[2:]
  match tail.find("**"[:]) {
    Some(pos) => {
      let inner_view = try! tail[:pos]
      let after = try! tail[pos + 2:]
      Some((@tmpx.strong([], render_inlines(inner_view.to_string())), after))
    }
    None => None
  }
}

///|
fn parse_em(rest : StringView) -> (@tmpx.Node, StringView)? {
  if !rest.has_prefix("*"[:]) {
    return None
  }
  let tail = try! rest[1:]
  match tail.find("*"[:]) {
    Some(pos) => {
      let inner_view = try! tail[:pos]
      let after = try! tail[pos + 1:]
      Some((@tmpx.em([], render_inlines(inner_view.to_string())), after))
    }
    None => None
  }
}

///|
fn parse_code_span(rest : StringView) -> (@tmpx.Node, StringView)? {
  if !rest.has_prefix("`"[:]) {
    return None
  }
  let tail = try! rest[1:]
  match tail.find("`"[:]) {
    Some(pos) => {
      let inner_view = try! tail[:pos]
      let after = try! tail[pos + 1:]
      Some((@tmpx.code([], [@tmpx.text(inner_view.to_string())]), after))
    }
    None => None
  }
}

///|
fn parse_image(rest : StringView) -> (@tmpx.Node, StringView)? {
  if !rest.has_prefix("!["[:]) {
    return None
  }
  let tail = try! rest[2:]
  match tail.find("]"[:]) {
    Some(close) => {
      let alt_view = try! tail[:close]
      let after_alt = try! tail[close + 1:]
      if !after_alt.has_prefix("("[:]) {
        return None
      }
      let url_tail = try! after_alt[1:]
      match url_tail.find(")"[:]) {
        Some(close_url) => {
          let url_view = try! url_tail[:close_url]
          let after = try! url_tail[close_url + 1:]
          match sanitize_image_src(url_view.to_string()) {
            Some(src) => {
              let alt = alt_view.to_string()
              Some((@tmpx.img([@tmpx.src(src), @tmpx.attr("alt", alt)]), after))
            }
            None => None
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
fn parse_link(rest : StringView) -> (@tmpx.Node, StringView)? {
  if !rest.has_prefix("["[:]) {
    return None
  }
  let tail = try! rest[1:]
  match tail.find("]"[:]) {
    Some(close) => {
      let label_view = try! tail[:close]
      let after_label = try! tail[close + 1:]
      if !after_label.has_prefix("("[:]) {
        return None
      }
      let url_tail = try! after_label[1:]
      match url_tail.find(")"[:]) {
        Some(close_url) => {
          let url_view = try! url_tail[:close_url]
          let after = try! url_tail[close_url + 1:]
          match sanitize_link(url_view.to_string()) {
            Some(url) => {
              let label_nodes = render_inlines(label_view.to_string())
              Some((@tmpx.a([@tmpx.href(url)], label_nodes), after))
            }
            None => None
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
fn sanitize_image_src(url : String) -> String? {
  let trimmed = url.trim().to_string()
  if trimmed.has_prefix("http://"[:]) ||
    trimmed.has_prefix("https://"[:]) ||
    trimmed.has_prefix("/"[:]) {
    Some(trimmed)
  } else {
    None
  }
}

///|
fn sanitize_link(url : String) -> String? {
  let trimmed = url.trim().to_string()
  if trimmed.has_prefix("http://"[:]) ||
    trimmed.has_prefix("https://"[:]) ||
    trimmed.has_prefix("/"[:]) ||
    trimmed.has_prefix("#"[:]) {
    Some(trimmed)
  } else {
    None
  }
}

///|
fn find_next_special(view : StringView) -> Int? {
  let mut min = update_min(None, view.find("**"[:]))
  min = update_min(min, view.find("*"[:]))
  min = update_min(min, view.find("`"[:]))
  min = update_min(min, view.find("!["[:]))
  update_min(min, view.find("["[:]))
}

///|
fn update_min(current : Int?, candidate : Int?) -> Int? {
  match (current, candidate) {
    (None, Some(v)) => Some(v)
    (Some(m), Some(v)) => Some(if v < m { v } else { m })
    (Some(m), None) => Some(m)
    (None, None) => None
  }
}

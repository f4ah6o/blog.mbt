///|
pub struct OgpData {
  title : String
  description : String
  image : String
  site_name : String
  url : String
}

///|
pub fn OgpData::empty() -> OgpData {
  { title: "", description: "", image: "", site_name: "", url: "" }
}

///|
pub fn parse_ogp_from_html(html : String) -> OgpData {
  let mut title = ""
  let mut description = ""
  let mut image = ""
  let mut site_name = ""
  let mut url = ""
  // Parse og:title
  match extract_meta_content(html, "og:title") {
    Some(v) => title = v
    None =>
      // Fallback to <title> tag
      match extract_title_tag(html) {
        Some(v) => title = v
        None => ()
      }
  }
  // Parse og:description
  match extract_meta_content(html, "og:description") {
    Some(v) => description = v
    None =>
      // Fallback to meta description
      match extract_meta_name_content(html, "description") {
        Some(v) => description = v
        None => ()
      }
  }
  // Parse og:image
  match extract_meta_content(html, "og:image") {
    Some(v) => image = v
    None => ()
  }
  // Parse og:site_name
  match extract_meta_content(html, "og:site_name") {
    Some(v) => site_name = v
    None => ()
  }
  // Parse og:url
  match extract_meta_content(html, "og:url") {
    Some(v) => url = v
    None => ()
  }
  { title, description, image, site_name, url }
}

///|
fn extract_meta_content(html : String, property : String) -> String? {
  // Look for <meta property="og:xxx" content="...">
  // or <meta content="..." property="og:xxx">
  let pattern1 = "property=\"" + property + "\""
  let pattern2 = "property='" + property + "'"
  let search = html.to_lower()
  let pattern1_lower = pattern1.to_lower()
  let pattern2_lower = pattern2.to_lower()
  // Try pattern1
  match search.find(pattern1_lower[:]) {
    Some(pos) => {
      // Find the containing <meta> tag
      let meta_start = find_meta_start(html, pos)
      let meta_end = find_tag_end(html, pos)
      if meta_start >= 0 && meta_end > meta_start {
        let meta_tag = try! html[meta_start:meta_end]
        return extract_content_attr(meta_tag.to_string())
      }
    }
    None => ()
  }
  // Try pattern2
  match search.find(pattern2_lower[:]) {
    Some(pos) => {
      let meta_start = find_meta_start(html, pos)
      let meta_end = find_tag_end(html, pos)
      if meta_start >= 0 && meta_end > meta_start {
        let meta_tag = try! html[meta_start:meta_end]
        return extract_content_attr(meta_tag.to_string())
      }
    }
    None => ()
  }
  None
}

///|
fn extract_meta_name_content(html : String, name : String) -> String? {
  let pattern1 = "name=\"" + name + "\""
  let pattern2 = "name='" + name + "'"
  let search = html.to_lower()
  let pattern1_lower = pattern1.to_lower()
  let pattern2_lower = pattern2.to_lower()
  match search.find(pattern1_lower[:]) {
    Some(pos) => {
      let meta_start = find_meta_start(html, pos)
      let meta_end = find_tag_end(html, pos)
      if meta_start >= 0 && meta_end > meta_start {
        let meta_tag = try! html[meta_start:meta_end]
        return extract_content_attr(meta_tag.to_string())
      }
    }
    None => ()
  }
  match search.find(pattern2_lower[:]) {
    Some(pos) => {
      let meta_start = find_meta_start(html, pos)
      let meta_end = find_tag_end(html, pos)
      if meta_start >= 0 && meta_end > meta_start {
        let meta_tag = try! html[meta_start:meta_end]
        return extract_content_attr(meta_tag.to_string())
      }
    }
    None => ()
  }
  None
}

///|
fn extract_title_tag(html : String) -> String? {
  let search = html.to_lower()
  match search.find("<title>"[:]) {
    Some(start) => {
      let content_start = start + 7
      match (try! search[content_start:]).find("</title>"[:]) {
        Some(end) => {
          let title_view = try! html[content_start:content_start + end]
          Some(decode_html_entities(title_view.to_string()))
        }
        None => None
      }
    }
    None => None
  }
}

///|
fn find_meta_start(html : String, pos : Int) -> Int {
  // Search backwards for '<'
  let mut i = pos
  while i >= 0 {
    let ch = char_at(html, i)
    if ch == '<' {
      return i
    }
    i = i - 1
  }
  -1
}

///|
fn find_tag_end(html : String, pos : Int) -> Int {
  // Search forwards for '>'
  let len = html.length()
  let mut i = pos
  while i < len {
    let ch = char_at(html, i)
    if ch == '>' {
      return i + 1
    }
    i = i + 1
  }
  -1
}

///|
fn char_at(s : String, index : Int) -> Char {
  let view = try! s[index:index + 1]
  for ch in view {
    return ch
  }
  '\u0000'
}

///|
fn extract_content_attr(tag : String) -> String? {
  // Look for content="..." or content='...'
  let tag_lower = tag.to_lower()
  match tag_lower.find("content=\""[:]) {
    Some(start) => {
      let value_start = start + 9
      let rest = try! tag[value_start:]
      match rest.find("\""[:]) {
        Some(end) => {
          let value = try! rest[:end]
          return Some(decode_html_entities(value.to_string()))
        }
        None => ()
      }
    }
    None => ()
  }
  match tag_lower.find("content='"[:]) {
    Some(start) => {
      let value_start = start + 9
      let rest = try! tag[value_start:]
      match rest.find("'"[:]) {
        Some(end) => {
          let value = try! rest[:end]
          return Some(decode_html_entities(value.to_string()))
        }
        None => ()
      }
    }
    None => ()
  }
  None
}

///|
fn decode_html_entities(s : String) -> String {
  let mut result = s
  result = result.replace(old="&amp;", new="&")
  result = result.replace(old="&lt;", new="<")
  result = result.replace(old="&gt;", new=">")
  result = result.replace(old="&quot;", new="\"")
  result = result.replace(old="&#39;", new="'")
  result = result.replace(old="&apos;", new="'")
  result
}

///|
pub fn ogp_to_link_card(ogp : OgpData, url : String) -> LinkCard {
  let title = if ogp.title.length() > 0 { ogp.title } else { url }
  LinkCard::new(url, title, ogp.description, ogp.image, ogp.site_name)
}

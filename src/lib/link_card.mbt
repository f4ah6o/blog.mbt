///|
pub struct LinkCard {
  url : String
  title : String
  description : String
  image_url : String
  site_name : String
}

///|
pub enum EmbedType {
  YouTube(String) // video_id
  Slide(String) // embed_url
  Unknown
}

///|
/// Pre-fetched embed data for server-side rendering
pub enum EmbedData {
  CardData(LinkCard)
  YouTubeId(String)
}

///|
pub fn EmbedData::card(card : LinkCard) -> EmbedData {
  CardData(card)
}

///|
pub fn EmbedData::youtube(video_id : String) -> EmbedData {
  YouTubeId(video_id)
}

///|
pub fn LinkCard::new(
  url : String,
  title : String,
  description : String,
  image_url : String,
  site_name : String,
) -> LinkCard {
  { url, title, description, image_url, site_name }
}

///|
pub fn LinkCard::default(url : String) -> LinkCard {
  { url, title: url, description: "", image_url: "", site_name: "" }
}

///|
pub fn parse_youtube_url(url : String) -> String? {
  // Handle youtube.com/watch?v=VIDEO_ID
  if url.contains("youtube.com/watch"[:]) {
    match url.find("v="[:]) {
      Some(start) => {
        let after_v = try! url[start + 2:]
        let video_id = extract_until_delimiter(after_v)
        if video_id.length() > 0 {
          return Some(video_id)
        }
      }
      None => ()
    }
  }
  // Handle youtu.be/VIDEO_ID
  if url.contains("youtu.be/"[:]) {
    match url.find("youtu.be/"[:]) {
      Some(start) => {
        let after_slash = try! url[start + 9:]
        let video_id = extract_until_delimiter(after_slash)
        if video_id.length() > 0 {
          return Some(video_id)
        }
      }
      None => ()
    }
  }
  None
}

///|
fn extract_until_delimiter(view : StringView) -> String {
  let sb = StringBuilder::new()
  for ch in view {
    if ch == '&' || ch == '?' || ch == '#' || ch == '/' {
      break
    }
    sb.write_char(ch)
  }
  sb.to_string()
}

///|
fn parse_google_slides_embed_url(url : String) -> String? {
  let prefix = "docs.google.com/presentation/d/"
  match url.find(prefix[:]) {
    Some(start) => {
      let after_prefix_view = try! url[start + prefix.length():]
      let after_prefix = after_prefix_view.to_string()
      let (is_published, id_view) = if after_prefix.has_prefix("e/"[:]) {
        (true, try! after_prefix[2:])
      } else {
        (false, after_prefix[:])
      }
      let deck_id = extract_until_delimiter(id_view)
      if deck_id.length() == 0 {
        None
      } else if is_published {
        Some("https://docs.google.com/presentation/d/e/" + deck_id + "/embed")
      } else {
        Some("https://docs.google.com/presentation/d/" + deck_id + "/embed")
      }
    }
    None => None
  }
}

///|
fn append_embed_mode_query(url : String) -> String {
  if url.contains("embed="[:]) {
    return url
  }
  match url.find("#"[:]) {
    Some(hash_pos) => {
      let base = (try! url[:hash_pos]).to_string()
      let hash = (try! url[hash_pos:]).to_string()
      let sep = if base.contains("?"[:]) { "&" } else { "?" }
      base + sep + "embed=1" + hash
    }
    None => {
      let sep = if url.contains("?"[:]) { "&" } else { "?" }
      url + sep + "embed=1"
    }
  }
}

///|
fn extract_url_path(url : String) -> String? {
  let trimmed = url.trim().to_string()
  if trimmed.has_prefix("/"[:]) {
    return Some(trimmed)
  }
  let scheme_len = if trimmed.has_prefix("https://"[:]) {
    8
  } else if trimmed.has_prefix("http://"[:]) {
    7
  } else {
    return None
  }
  let rest_view = try! trimmed[scheme_len:]
  let rest = rest_view.to_string()
  match rest.find("/"[:]) {
    Some(pos) => Some((try! trimmed[scheme_len + pos:]).to_string())
    None => None
  }
}

///|
fn parse_internal_post_slide_url(url : String) -> String? {
  let trimmed = url.trim().to_string()
  let path = match extract_url_path(trimmed) {
    Some(v) => v
    None => return None
  }
  if !path.has_prefix("/posts/"[:]) {
    return None
  }
  let slug_view = try! path[7:]
  let slug = extract_until_delimiter(slug_view)
  if slug.length() == 0 {
    return None
  }
  if slug.has_suffix(".md"[:]) {
    return None
  }
  Some(append_embed_mode_query(trimmed))
}

///|
fn parse_slide_url(url : String) -> String? {
  let trimmed = url.trim().to_string()
  match parse_internal_post_slide_url(trimmed) {
    Some(embed_url) => return Some(embed_url)
    None => ()
  }
  if !trimmed.has_prefix("http://"[:]) && !trimmed.has_prefix("https://"[:]) {
    return None
  }

  match parse_google_slides_embed_url(trimmed) {
    Some(embed_url) => return Some(embed_url)
    None => ()
  }

  if trimmed.contains("speakerdeck.com/player/"[:]) {
    return Some(trimmed)
  }
  if trimmed.contains("slideshare.net/slideshow/embed_code/"[:]) {
    return Some(trimmed)
  }
  if trimmed.contains("docswell.com/slide/"[:]) && trimmed.contains("/embed"[:]) {
    return Some(trimmed)
  }
  None
}

///|
pub fn detect_embed_type(url : String) -> EmbedType {
  match parse_youtube_url(url) {
    Some(video_id) => return YouTube(video_id)
    None => ()
  }
  match parse_slide_url(url) {
    Some(embed_url) => return Slide(embed_url)
    None => ()
  }
  Unknown
}

///|
pub fn render_link_card(card : LinkCard) -> @tmpx.Node {
  // Check if this is a placeholder card (needs OGP fetch)
  let needs_fetch = card.title == card.url && card.description.length() == 0
  let image_node = if card.image_url.length() > 0 {
    @tmpx.img([
      @tmpx.class_("link-card-image"),
      @tmpx.src(card.image_url),
      @tmpx.attr("alt", card.title),
    ])
  } else {
    @tmpx.div([@tmpx.class_("link-card-image link-card-image-placeholder")], [])
  }
  let site_node = @tmpx.span([@tmpx.class_("link-card-site")], [
    @tmpx.text(card.site_name),
  ])
  let description_node = @tmpx.p([@tmpx.class_("link-card-description")], [
    @tmpx.text(card.description),
  ])
  let class_name = if needs_fetch {
    "link-card link-card-loading"
  } else {
    "link-card"
  }
  @tmpx.a(
    [
      @tmpx.class_(class_name),
      @tmpx.href(card.url),
      @tmpx.data_attr("url", card.url),
      @tmpx.attr("target", "_blank"),
      @tmpx.rel("noopener noreferrer"),
    ],
    [
      image_node,
      @tmpx.div([@tmpx.class_("link-card-content")], [
        @tmpx.div([@tmpx.class_("link-card-title")], [@tmpx.text(card.title)]),
        description_node,
        site_node,
      ]),
    ],
  )
}

///|
pub fn render_embed(embed_type : EmbedType, url : String) -> @tmpx.Node {
  match embed_type {
    YouTube(video_id) => render_youtube_embed(video_id)
    Slide(embed_url) => render_slide_embed(embed_url)
    Unknown => render_link_card(LinkCard::default(url))
  }
}

///|
fn render_youtube_embed(video_id : String) -> @tmpx.Node {
  let embed_url = "https://www.youtube.com/embed/" + video_id
  @tmpx.div([@tmpx.class_("embed-card embed-youtube")], [
    @tmpx.iframe(
      [
        @tmpx.src(embed_url),
        @tmpx.attr("frameborder", "0"),
        @tmpx.attr(
          "allow", "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture",
        ),
        @tmpx.attr("allowfullscreen", "true"),
      ],
      [],
    ),
  ])
}

///|
fn render_slide_embed(embed_url : String) -> @tmpx.Node {
  @tmpx.div([@tmpx.class_("embed-card embed-slide")], [
    @tmpx.iframe(
      [
        @tmpx.src(embed_url),
        @tmpx.attr("frameborder", "0"),
        @tmpx.attr("allowfullscreen", "true"),
        @tmpx.attr("loading", "lazy"),
      ],
      [],
    ),
  ])
}

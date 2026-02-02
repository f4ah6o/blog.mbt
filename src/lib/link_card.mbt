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
pub fn detect_embed_type(url : String) -> EmbedType {
  match parse_youtube_url(url) {
    Some(video_id) => return YouTube(video_id)
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

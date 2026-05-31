///|
pub type LinkCard = @papyr_content.LinkCard

///|
pub type EmbedType = @papyr_content.EmbedType

///|
pub type EmbedData = @papyr_content.EmbedData

///|
pub fn parse_youtube_url(url : String) -> String? {
  @papyr_content.parse_youtube_url(url)
}

///|
pub fn detect_embed_type(url : String) -> EmbedType {
  @papyr_content.detect_embed_type(url)
}

///|
pub fn detect_youtube_video_id(url : String) -> String? {
  match @papyr_content.detect_embed_type(url) {
    @papyr_content.YouTube(video_id) => Some(video_id)
    _ => None
  }
}

///|
pub fn is_slide_embed_url(url : String) -> Bool {
  match @papyr_content.detect_embed_type(url) {
    @papyr_content.Slide(_) => true
    _ => false
  }
}

///|
pub fn render_link_card(card : LinkCard) -> @tmpx.Node {
  @papyr_content.render_link_card(card)
}

///|
pub fn render_embed(embed_type : EmbedType, url : String) -> @tmpx.Node {
  @papyr_content.render_embed(embed_type, url)
}

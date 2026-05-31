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

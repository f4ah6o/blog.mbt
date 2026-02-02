///|
pub fn post_detail_content(post : @models.BlogPost) -> @tmpx.Node {
  post_detail_content_with_embeds(post, @hashmap.new())
}

///|
pub fn post_detail_content_with_embeds(
  post : @models.BlogPost,
  embed_data : @hashmap.HashMap[String, @lib.EmbedData],
) -> @tmpx.Node {
  @tmpx.article([@tmpx.class_("post-detail")], [
    @tmpx.header_([@tmpx.class_("post-header")], [
      @tmpx.h1([], [@tmpx.text(post.title)]),
      @tmpx.div([@tmpx.class_("post-meta")], [
        @tmpx.time([@tmpx.attr("datetime", post.published_at)], [
          @tmpx.text(format_date(post.published_at)),
        ]),
      ]),
    ]),
    @tmpx.div([@tmpx.class_("post-content")], [
      @lib.render_markdown_with_embeds(post.content, embed_data),
    ]),
    @tmpx.footer([@tmpx.class_("post-footer")], [
      @tmpx.a([@tmpx.href("/posts"), @tmpx.class_("btn")], [
        @tmpx.text("Back to Posts"),
      ]),
    ]),
  ])
}

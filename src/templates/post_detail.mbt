///|
pub fn post_detail_content(post : @models.BlogPost) -> @tmpx.Node {
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
      @tmpx.p([], [@tmpx.text(post.content)]),
    ]),
    @tmpx.footer([@tmpx.class_("post-footer")], [
      @tmpx.a([@tmpx.href("/posts"), @tmpx.class_("btn")], [
        @tmpx.text("Back to Posts"),
      ]),
    ]),
  ])
}

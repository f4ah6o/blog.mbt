///|
pub fn layout(title : String, content : @tmpx.Node) -> String {
  let page = @tmpx.raw_html("<!DOCTYPE html>")
  let html = @tmpx.html_([@tmpx.lang_attr("en")], [
    @tmpx.head([], [
      @tmpx.meta([@tmpx.charset("UTF-8")]),
      @tmpx.meta([
        @tmpx.attr("name", "viewport"),
        @tmpx.content("width=device-width, initial-scale=1.0"),
      ]),
      @tmpx.title([], [@tmpx.text(title)]),
      @tmpx.link([@tmpx.rel("stylesheet"), @tmpx.href("/static/styles.css")]),
    ]),
    @tmpx.body([], [
      @tmpx.nav([@tmpx.class_("navbar")], [
        @tmpx.div([@tmpx.class_("container")], [
          @tmpx.a([@tmpx.href("/"), @tmpx.class_("logo")], [
            @tmpx.text("MoonBit Blog"),
          ]),
          @tmpx.ul([@tmpx.class_("nav-links")], [
            @tmpx.li([], [
              @tmpx.a([@tmpx.href("/posts")], [@tmpx.text("Posts")]),
            ]),
          ]),
        ]),
      ]),
      @tmpx.main_([@tmpx.id_("content"), @tmpx.class_("container")], [
        @tmpx.div([@tmpx.id_("posts-container")], [content]),
      ]),
      @tmpx.footer([@tmpx.class_("footer")], [
        @tmpx.div([@tmpx.class_("container")], [
          @tmpx.p([], [
            @tmpx.text("Built with MoonBit, TMPX, MHX, and Cloudflare Workers"),
          ]),
        ]),
      ]),
      @tmpx.script([@tmpx.src("/mhx.js"), @tmpx.bool_attr("defer")], []),
    ]),
  ])
  @tmpx.render(@tmpx.fragment([page, html]))
}

///|
pub fn error_layout(title : String, message : String) -> String {
  layout(
    title,
    @tmpx.div([@tmpx.class_("error-page")], [
      @tmpx.h1([], [@tmpx.text(title)]),
      @tmpx.p([], [@tmpx.text(message)]),
      @tmpx.a([@tmpx.href("/posts"), @tmpx.class_("btn")], [
        @tmpx.text("Back to Posts"),
      ]),
    ]),
  )
}

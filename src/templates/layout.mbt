///|
/// Page metadata for OGP and Twitter Card generation
pub(all) struct PageMeta {
  title : String
  description : String
  url : String
  og_type : String
  image_url : String?
  twitter_card : String?
}

///|
/// Convert relative path to absolute URL
fn abs_url(path_or_url : String) -> String {
  if path_or_url.has_prefix("http://") || path_or_url.has_prefix("https://") {
    path_or_url
  } else {
    let base = @config.SITE_URL
    if base.has_suffix("/") && path_or_url.has_prefix("/") {
      // Remove leading slash from path using pattern matching
      let path_view = path_or_url.view()
      match path_view {
        ['/', .. rest] => base + rest.to_string()
        _ => base + path_or_url
      }
    } else if not(base.has_suffix("/")) && not(path_or_url.has_prefix("/")) {
      base + "/" + path_or_url
    } else {
      base + path_or_url
    }
  }
}

///|
/// Normalize description text for meta tags
/// - Removes markdown syntax (simple approach)
/// - Limits length to ~200 chars
/// - Collapses whitespace
fn normalize_description(text : String) -> String raise {
  // Remove common markdown patterns
  let cleaned = text
    .replace_all(old="# ", new="")
    .replace_all(old="## ", new="")
    .replace_all(old="### ", new="")
    .replace_all(old="**", new="")
    .replace_all(old="*", new="")
    .replace_all(old="`", new="")
    .replace_all(old="[", new="")
    .replace_all(old="]", new="")
    .replace_all(old="(", new="")
    .replace_all(old=")", new="")

  // Trim whitespace - note: trim() returns StringView, so we need to convert
  let normalized = cleaned.trim()

  // Convert to String and limit length (truncate with ellipsis if too long)
  let result = normalized.to_string()
  if result.length() > 200 {
    // Use view and pattern matching to safely get first 197 chars
    let view = result.view()
    let truncated = view[:197].to_string()
    truncated + "..."
  } else {
    result
  }
}

///|
/// Generate meta tags for OGP and Twitter Card
fn meta_tags(meta : PageMeta?) -> Array[@tmpx.Node] raise {
  let tags : Array[@tmpx.Node] = []

  // Determine values (use page meta or fall back to site defaults)
  let title = match meta {
    Some(m) => m.title
    None => @config.SITE_NAME
  }
  let description = match meta {
    Some(m) => normalize_description(m.description)
    None => @config.SITE_DESCRIPTION
  }
  let url = match meta {
    Some(m) => abs_url(m.url)
    None => @config.SITE_URL
  }
  let og_type = match meta {
    Some(m) => m.og_type
    None => "website"
  }

  // Image: use page-specific if provided, otherwise default
  let image_url = match meta {
    Some(m) =>
      match m.image_url {
        Some(img) => abs_url(img)
        None => abs_url(@config.DEFAULT_OG_IMAGE)
      }
    None => abs_url(@config.DEFAULT_OG_IMAGE)
  }

  // Twitter card type: summary_large_image if we have an image, otherwise summary
  let twitter_card_type = match meta {
    Some(m) =>
      match m.twitter_card {
        Some(tc) => tc
        None =>
          if image_url != abs_url(@config.DEFAULT_OG_IMAGE) {
            "summary_large_image"
          } else {
            "summary"
          }
      }
    None => "summary"
  }

  // Standard meta description (always included)
  tags.push(
    @tmpx.meta([@tmpx.attr("name", "description"), @tmpx.content(description)]),
  )

  // Open Graph tags
  tags.push(
    @tmpx.meta([@tmpx.attr("property", "og:title"), @tmpx.content(title)]),
  )
  tags.push(
    @tmpx.meta([
      @tmpx.attr("property", "og:description"),
      @tmpx.content(description),
    ]),
  )
  tags.push(
    @tmpx.meta([@tmpx.attr("property", "og:type"), @tmpx.content(og_type)]),
  )
  tags.push(@tmpx.meta([@tmpx.attr("property", "og:url"), @tmpx.content(url)]))
  tags.push(
    @tmpx.meta([
      @tmpx.attr("property", "og:site_name"),
      @tmpx.content(@config.SITE_NAME),
    ]),
  )
  tags.push(
    @tmpx.meta([@tmpx.attr("property", "og:image"), @tmpx.content(image_url)]),
  )

  // Twitter Card tags
  tags.push(
    @tmpx.meta([
      @tmpx.attr("name", "twitter:card"),
      @tmpx.content(twitter_card_type),
    ]),
  )
  tags.push(
    @tmpx.meta([@tmpx.attr("name", "twitter:title"), @tmpx.content(title)]),
  )
  tags.push(
    @tmpx.meta([
      @tmpx.attr("name", "twitter:description"),
      @tmpx.content(description),
    ]),
  )
  tags.push(
    @tmpx.meta([@tmpx.attr("name", "twitter:image"), @tmpx.content(image_url)]),
  )
  tags
}

///|
pub fn layout_with_meta(
  title : String,
  content : @tmpx.Node,
  meta : PageMeta,
) -> String raise {
  let page = @tmpx.raw_html("<!DOCTYPE html>")
  let meta_nodes = meta_tags(Some(meta))
  let html = @tmpx.html_([@tmpx.lang_attr("en")], [
    @tmpx.head(
      [],
      [
        @tmpx.meta([@tmpx.charset("UTF-8")]),
        @tmpx.meta([
          @tmpx.attr("name", "viewport"),
          @tmpx.content("width=device-width, initial-scale=1.0"),
        ]),
        @tmpx.title([], [@tmpx.text(title)]),
        @tmpx.link([@tmpx.rel("stylesheet"), @tmpx.href("/styles.css")]),
        ..meta_nodes,
      ],
    ),
    @tmpx.body([], [
      @tmpx.nav([@tmpx.class_("navbar")], [
        @tmpx.div([@tmpx.class_("container")], [
          @tmpx.a([@tmpx.href("/"), @tmpx.class_("logo")], [
            @tmpx.text(@config.SITE_TITLE),
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
          @tmpx.p([], [@tmpx.text(@config.FOOTER_TEXT)]),
        ]),
      ]),
      @tmpx.script([@tmpx.src("/mhx.js"), @tmpx.bool_attr("defer")], []),
    ]),
  ])
  @tmpx.render(@tmpx.fragment([page, html]))
}

///|
pub fn layout(title : String, content : @tmpx.Node) -> String raise {
  let page = @tmpx.raw_html("<!DOCTYPE html>")
  let meta_nodes = meta_tags(None)
  let html = @tmpx.html_([@tmpx.lang_attr("en")], [
    @tmpx.head(
      [],
      [
        @tmpx.meta([@tmpx.charset("UTF-8")]),
        @tmpx.meta([
          @tmpx.attr("name", "viewport"),
          @tmpx.content("width=device-width, initial-scale=1.0"),
        ]),
        @tmpx.title([], [@tmpx.text(title)]),
        @tmpx.link([@tmpx.rel("stylesheet"), @tmpx.href("/styles.css")]),
        ..meta_nodes,
      ],
    ),
    @tmpx.body([], [
      @tmpx.nav([@tmpx.class_("navbar")], [
        @tmpx.div([@tmpx.class_("container")], [
          @tmpx.a([@tmpx.href("/"), @tmpx.class_("logo")], [
            @tmpx.text(@config.SITE_TITLE),
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
          @tmpx.p([], [@tmpx.text(@config.FOOTER_TEXT)]),
        ]),
      ]),
      @tmpx.script([@tmpx.src("/mhx.js"), @tmpx.bool_attr("defer")], []),
    ]),
  ])
  @tmpx.render(@tmpx.fragment([page, html]))
}

///|
pub fn error_layout(title : String, message : String) -> String raise {
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

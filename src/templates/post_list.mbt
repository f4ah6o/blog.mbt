///|
fn post_card(post : @models.BlogPost) -> @tmpx.Node {
  @tmpx.article([@tmpx.class_("post-card")], [
    @tmpx.h2([@tmpx.class_("post-title")], [
      @tmpx.a([@tmpx.href("/posts/" + post.slug)], [@tmpx.text(post.title)]),
    ]),
    @tmpx.p([@tmpx.class_("post-excerpt")], [@tmpx.text(post.excerpt)]),
    @tmpx.div([@tmpx.class_("post-meta")], [
      @tmpx.time([@tmpx.attr("datetime", post.published_at)], [
        @tmpx.text(format_date(post.published_at)),
      ]),
    ]),
  ])
}

///|
fn format_date(iso_date : String) -> String {
  // Extract date portion from ISO 8601: "2026-01-30T00:00:00Z" -> "2026-01-30"
  if iso_date.length() >= 10 {
    let chars = iso_date.to_array()
    let date_chars : Array[Char] = []
    for i = 0; i < 10; i = i + 1 {
      date_chars.push(chars[i])
    }
    String::from_array(date_chars)
  } else {
    iso_date
  }
}

///|
fn pagination_buttons(page : Int, total_pages : Int, limit : Int) -> @tmpx.Node {
  let prev_disabled = page <= 1
  let next_disabled = page >= total_pages
  let prev_attrs : Array[@tmpx.Attr] = if prev_disabled {
    [@tmpx.class_("btn btn-prev"), @tmpx.disabled()]
  } else {
    let prev_url = "/api/posts?page=" +
      (page - 1).to_string() +
      "&limit=" +
      limit.to_string()
    [
      @tmpx.class_("btn btn-prev"),
      @tmpx.mx_get(prev_url),
      @tmpx.mx_target("#posts-container"),
      @tmpx.mx_swap(@tmpx.inner_html()),
      @tmpx.mx_push_url_custom(
        "/posts?page=" + (page - 1).to_string() + "&limit=" + limit.to_string(),
      ),
    ]
  }
  let next_attrs : Array[@tmpx.Attr] = if next_disabled {
    [@tmpx.class_("btn btn-next"), @tmpx.disabled()]
  } else {
    let next_url = "/api/posts?page=" +
      (page + 1).to_string() +
      "&limit=" +
      limit.to_string()
    [
      @tmpx.class_("btn btn-next"),
      @tmpx.mx_get(next_url),
      @tmpx.mx_target("#posts-container"),
      @tmpx.mx_swap(@tmpx.inner_html()),
      @tmpx.mx_push_url_custom(
        "/posts?page=" + (page + 1).to_string() + "&limit=" + limit.to_string(),
      ),
    ]
  }
  @tmpx.div([@tmpx.class_("pagination")], [
    @tmpx.button(prev_attrs, [@tmpx.text("Prev")]),
    @tmpx.span([@tmpx.class_("page-info")], [
      @tmpx.text("Page " + page.to_string() + " of " + total_pages.to_string()),
    ]),
    @tmpx.button(next_attrs, [@tmpx.text("Next")]),
  ])
}

///|
pub fn post_list_content(
  posts : Array[@models.BlogPost],
  page : Int,
  total_pages : Int,
  limit : Int,
) -> @tmpx.Node {
  if posts.is_empty() {
    return @tmpx.div([@tmpx.class_("empty-list")], [
      @tmpx.p([], [@tmpx.text("No posts found.")]),
    ])
  }
  let cards : Array[@tmpx.Node] = []
  for post in posts {
    cards.push(post_card(post))
  }
  cards.push(pagination_buttons(page, total_pages, limit))
  @tmpx.fragment(cards)
}

///|
pub fn render_post_list(
  posts : Array[@models.BlogPost],
  page : Int,
  total_pages : Int,
  limit : Int,
) -> String {
  @tmpx.render(post_list_content(posts, page, total_pages, limit))
}

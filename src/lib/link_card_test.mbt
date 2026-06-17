///|
test "detect internal slide embed url (relative)" {
  match detect_embed_type("/posts/svg-slide-demo") {
    @papyr_content.Slide(embed_url) =>
      inspect(embed_url, content="/posts/svg-slide-demo?embed=1")
    _ => fail("expected Slide embed")
  }
}

///|
test "detect internal slide embed url (absolute)" {
  match detect_embed_type("https://blog.f12o.com/posts/svg-slide-demo#2") {
    @papyr_content.Slide(embed_url) =>
      inspect(
        embed_url,
        content="https://blog.f12o.com/posts/svg-slide-demo?embed=1#2",
      )
    _ => fail("expected Slide embed")
  }
}

///|
test "do not treat markdown export url as slide embed" {
  match detect_embed_type("/posts/svg-slide-demo.md") {
    @papyr_content.Unknown => ()
    _ => fail("markdown export should not be embedded as slide")
  }
}

///|
test "extract og image from local markdown image" {
  inspect(
    extract_og_image_url("# Title\n\n![screen](/images/demo.png)\n"),
    content="Some(/images/demo.png)",
  )
}

///|
test "extract og image from external markdown image" {
  inspect(
    extract_og_image_url("Intro ![screen](https://example.com/demo.webp)"),
    content="Some(https://example.com/demo.webp)",
  )
}

///|
test "ignore invalid og image urls" {
  inspect(
    extract_og_image_url(
      "![relative](images/demo.png)\n![bad](javascript:alert(1))",
    ),
    content="None",
  )
}

///|
test "ignore markdown images inside fenced code blocks" {
  inspect(
    extract_og_image_url(
      "```md\n![code](/images/code.png)\n```\n![real](/images/real.png)",
    ),
    content="Some(/images/real.png)",
  )
}

///|
test "skip badge images for og image" {
  inspect(
    extract_og_image_url(
      "[![CI](https://github.com/f4ah6o/bdg-rs/actions/workflows/rust.yaml/badge.svg)](https://github.com/f4ah6o/bdg-rs/actions)\n![screen](/images/screen.png)",
    ),
    content="Some(/images/screen.png)",
  )
}

///|
test "return none when only badge images exist" {
  inspect(
    extract_og_image_url(
      "[![crates.io](https://img.shields.io/crates/v/bdg.svg)](https://crates.io/crates/bdg)",
    ),
    content="None",
  )
}

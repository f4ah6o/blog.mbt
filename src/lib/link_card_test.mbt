///|
test "detect internal slide embed url (relative)" {
  match detect_embed_type("/posts/svg-slide-demo") {
    Slide(embed_url) =>
      inspect(embed_url, content="/posts/svg-slide-demo?embed=1")
    _ => fail("expected Slide embed")
  }
}

///|
test "detect internal slide embed url (absolute)" {
  match detect_embed_type("https://blog.f12o.com/posts/svg-slide-demo#2") {
    Slide(embed_url) =>
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
    Unknown => ()
    _ => fail("markdown export should not be embedded as slide")
  }
}

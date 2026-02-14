///|
test "available themes include ocean" {
  inspect(available_slide_themes().contains("ocean"), content="true")
}

///|
test "parse slide front matter" {
  let content =
    #|---
    #|slide_theme: sunrise
    #|---
    #|
    #|## Slide A
    #|- hello
    #|
  let parsed = parse_slide_front_matter(content)
  inspect(
    parsed,
    content="Ok({slide_theme: \"sunrise\", body: \"\\n## Slide A\\n- hello\\n\"})",
  )
}

///|
test "validate slide markdown requires h2" {
  let invalid = "no headings"
  inspect(
    validate_slide_markdown(invalid),
    content="Some(\"Slide content must contain at least one H2 heading (`## title`).\")",
  )
}

///|
test "render svg slides scales up when content is short" {
  let result = render_svg_slides("## Intro\n- hello\n", "Deck", "classic")
  match result {
    Ok(svgs) => {
      inspect(svgs.length(), content="1")
      inspect(
        svgs[0].contains("font-size=\"46\" fill=\"#cbd5e1\""[:]),
        content="true",
      )
    }
    Err(msg) => fail("unexpected render error: " + msg)
  }
}

///|
test "render svg slides truncates when content is dense" {
  let sb = StringBuilder::new()
  sb.write_string("## Dense\n")
  for i = 0; i < 40; i = i + 1 {
    sb.write_string("- item ")
    sb.write_string(i.to_string())
    sb.write_string(
      " with many words to overflow the slide body area quickly\n",
    )
  }
  let result = render_svg_slides(sb.to_string(), "Deck", "classic")
  match result {
    Ok(svgs) => {
      inspect(
        svgs[0].contains("font-size=\"24\" fill=\"#cbd5e1\""[:]),
        content="true",
      )
      inspect(svgs[0].contains("…"[:]), content="true")
    }
    Err(msg) => fail("unexpected render error: " + msg)
  }
}

///|
test "render slide deck page" {
  let content =
    #|---
    #|slide_theme: classic
    #|---
    #|
    #|## Intro
    #|- One
    #|
    #|## End
    #|- Two
    #|
  let rendered = render_slide_deck_page("Deck Title", "deck-title", content)
  match rendered {
    Ok(html) => {
      inspect(html.contains("slide-viewport"[:]), content="true")
      inspect(html.contains("Deck Title"[:]), content="true")
      inspect(html.contains("Theme: Classic"[:]), content="true")
      inspect(html.contains("data-text-inc"[:]), content="true")
      inspect(html.contains("data-text-scale"[:]), content="true")
    }
    Err(msg) => fail("unexpected render error: " + msg)
  }
}

///|
test "render slide deck page in embed mode" {
  let content =
    #|---
    #|slide_theme: classic
    #|---
    #|
    #|## Intro
    #|- One
    #|
  let rendered = render_slide_deck_page(
    "Deck Title",
    "deck-title",
    content,
    embed_mode=true,
  )
  match rendered {
    Ok(html) => {
      inspect(html.contains("slide-deck-embed"[:]), content="true")
      inspect(html.contains("Back to Posts"[:]), content="false")
      inspect(html.contains("slide-embed-footer"[:]), content="true")
      inspect(html.contains("slide-embed-nav"[:]), content="true")
      inspect(html.contains("data-text-reset"[:]), content="true")
      inspect(html.contains("data-slide-fullscreen"[:]), content="true")
      inspect(html.contains("Markdown"[:]), content="false")
    }
    Err(msg) => fail("unexpected render error: " + msg)
  }
}

import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { export_posts, parse_wrangler_json, render_article, verify_round_trip } from "./export_posts.mjs";

test("renders a blog post with explicit visibility metadata", () => {
  const markdown = render_article({
    title: "A title",
    slug: "a-title",
    excerpt: "An excerpt",
    content: "Body\n",
    slide_flag: 0,
    status: "published",
    visibility: "public",
    published_at: "2026-07-23T00:00:00Z",
    updated_at: "2026-07-23T01:00:00Z",
  });
  assert.match(markdown, /type: "Blog Post"/);
  assert.match(markdown, /visibility: "public"/);
  assert.match(markdown, /Body/);
});

test("preserves legacy slide front matter inside the OKF article", () => {
  const markdown = render_article({
    title: "Slides",
    slug: "slides",
    content: "---\nslide_theme: sunrise\n---\n\n## One\n",
    slide_flag: 1,
    status: "draft",
    visibility: "private",
    published_at: null,
    updated_at: "2026-07-23T01:00:00Z",
  });
  assert.equal((markdown.match(/---/g) ?? []).length, 4);
  assert.match(markdown, /slide_theme: "sunrise"/);
  assert.match(markdown, /## One/);
});

test("parses Wrangler JSON result envelopes", () => {
  assert.deepEqual(
    parse_wrangler_json(JSON.stringify([{ results: [{ slug: "one" }] }, { results: [{ slug: "two" }] }])),
    [{ slug: "one" }, { slug: "two" }],
  );
});

test("exports a complete OKF bundle", () => {
  const directory = mkdtempSync(join(tmpdir(), "blog-export-test-"));
  try {
    const result = export_posts(
      [{ title: "One", slug: "one", content: "Body\n", slide_flag: 0, status: "draft", visibility: "private", updated_at: "2026-07-23" }],
      directory,
    );
    assert.equal(result.post_count, 1);
    assert.match(readFileSync(join(directory, "index.md"), "utf8"), /Knowledge/);
    assert.match(readFileSync(join(directory, "articles", "one.md"), "utf8"), /slug: "one"/);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

test("verifies exported rows after re-import", () => {
  const directory = mkdtempSync(join(tmpdir(), "blog-round-trip-test-"));
  try {
    const rows = [{ title: "One", slug: "one", excerpt: "", content: "Body", slide_flag: 0, status: "draft", visibility: "private", published_at: null, updated_at: "2026-07-23" }];
    export_posts(rows, directory);
    assert.deepEqual(verify_round_trip(rows, directory), []);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

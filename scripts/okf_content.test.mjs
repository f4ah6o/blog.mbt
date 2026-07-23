import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import {
  generate_sync_sql,
  load_bundle,
  parse_front_matter,
  post_rows,
  validate_bundle,
} from "./okf_content.mjs";

function with_bundle(files, callback) {
  const directory = mkdtempSync(join(tmpdir(), "blog-okf-test-"));
  try {
    for (const [relative_path, content] of Object.entries(files)) {
      const file_path = join(directory, relative_path);
      mkdirSync(join(file_path, ".."), { recursive: true });
      writeFileSync(file_path, content, "utf8");
    }
    return callback(directory);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

test("parses OKF scalar front matter and preserves the body", () => {
  const page = parse_front_matter(
    `---\ntype: Blog Post\ntitle: "A # title"\ntags:\n  - okf\n  - preview\n---\n\n# Body\n`,
    "articles/example.md",
  );

  assert.equal(page.metadata.type, "Blog Post");
  assert.equal(page.metadata.title, "A # title");
  assert.equal(page.metadata.tags, null);
  assert.equal(page.body, "# Body\n");
});

test("loads the bundle and projects only site article types", () => {
  with_bundle(
    {
      "index.md": "# Knowledge\n",
      "log.md": "# Log\n",
      "articles/public.md": `---\ntype: Blog Post\ntitle: Public\nslug: public\nstatus: published\nvisibility: public\ntimestamp: 2026-07-23T00:00:00Z\npublished_at: 2026-07-23T00:00:00Z\n---\n\nPublic body\n`,
      "articles/draft-slide.md": `---\ntype: Slide Deck\ntitle: Draft slide\nslug: draft-slide\nstatus: draft\nvisibility: private\ntimestamp: 2026-07-23T01:00:00Z\npublished_at: null\n---\n\nSlide body\n`,
      "concepts/d1.md": `---\ntype: Concept\ntitle: D1\n---\n\nConcept body\n`,
    },
    (directory) => {
      const bundle = load_bundle(directory);
      assert.deepEqual(validate_bundle(bundle), []);
      const rows = post_rows(bundle);
      assert.equal(rows.length, 2);
      assert.deepEqual(rows.map((row) => row.slug), ["draft-slide", "public"]);
      assert.equal(rows[0].slide_flag, 1);
      assert.equal(rows[0].published_at, null);
      assert.equal(rows[0].visibility, "private");
      assert.match(rows[0].content, /^---\nslide_theme: classic\n---\n\nSlide body/);
    },
  );
});

test("rejects invalid article visibility and duplicate slugs", () => {
  with_bundle(
    {
      "index.md": "# Knowledge\n",
      "log.md": "# Log\n",
      "articles/first.md": `---\ntype: Blog Post\ntitle: First\nslug: same\nstatus: published\nvisibility: public\ntimestamp: 2026-07-23\n---\n`,
      "articles/second.md": `---\ntype: Blog Post\ntitle: Second\nslug: same\nstatus: review\nvisibility: internal\ntimestamp: 2026-07-24\n---\n`,
      "notes/unknown.md": `---\ntype: Mystery\n---\n`,
    },
    (directory) => {
      const errors = validate_bundle(load_bundle(directory));
      assert.equal(errors.length, 4);
      assert.ok(errors.some((error) => error.includes("duplicate slug same")));
      assert.ok(errors.some((error) => error.includes("invalid status: review")));
      assert.ok(errors.some((error) => error.includes("invalid visibility: internal")));
      assert.ok(errors.some((error) => error.includes("invalid type: Mystery")));
    },
  );
});

test("generates id-preserving upserts and removes stale local rows", () => {
  with_bundle(
    {
      "index.md": "# Knowledge\n",
      "log.md": "# Log\n",
      "articles/quote.md": `---\ntype: Blog Post\ntitle: O'Reilly\nslug: quote\nstatus: draft\nvisibility: private\ntimestamp: 2026-07-23\n---\n\nBody\n`,
    },
    (directory) => {
      const sql = generate_sync_sql(load_bundle(directory));
      assert.match(sql, /ON CONFLICT\(slug\) DO UPDATE SET/);
      assert.match(sql, /DELETE FROM posts WHERE slug NOT IN \('quote'\);/);
      assert.doesNotMatch(sql, /BEGIN TRANSACTION;\n\nDELETE FROM posts;/);
      assert.match(sql, /O''Reilly/);
      assert.match(sql, /visibility/);
    },
  );
});

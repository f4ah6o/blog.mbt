import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";

import { load_bundle, post_rows } from "./okf_content.mjs";

const QUERY = [
  "SELECT title, slug, excerpt, content, slide_flag, status, published_at, updated_at, visibility",
  "FROM posts ORDER BY id",
].join(" ");

function yaml_value(value) {
  if (value === null || value === undefined || value === "") return "null";
  return JSON.stringify(String(value));
}

function extract_slide_theme(content) {
  if (!content.startsWith("---\n")) return { slide_theme: "classic", content };
  const closing_marker = content.indexOf("\n---", 4);
  if (closing_marker < 0) return { slide_theme: "classic", content };
  const header = content.slice(4, closing_marker);
  const theme_line = header.split("\n").find((line) => line.trim().startsWith("slide_theme:"));
  const slide_theme = theme_line ? theme_line.slice(theme_line.indexOf(":") + 1).trim() || "classic" : "classic";
  return { slide_theme, content };
}

export function render_article(row) {
  const is_slide = Number(row.slide_flag) === 1;
  const slide = is_slide ? extract_slide_theme(String(row.content ?? "")) : { slide_theme: null, content: String(row.content ?? "") };
  const lines = [
    "---",
    `type: ${yaml_value(is_slide ? "Slide Deck" : "Blog Post")}`,
    `title: ${yaml_value(row.title)}`,
    `slug: ${yaml_value(row.slug)}`,
    `excerpt: ${yaml_value(row.excerpt)}`,
    `status: ${yaml_value(row.status || "draft")}`,
    `visibility: ${yaml_value(row.visibility || "public")}`,
    `published_at: ${yaml_value(row.published_at)}`,
    `timestamp: ${yaml_value(row.updated_at)}`,
  ];
  if (is_slide) lines.push(`slide_theme: ${yaml_value(slide.slide_theme)}`);
  lines.push("---", "", slide.content);
  return lines.join("\n");
}

export function verify_round_trip(rows, output_directory) {
  const exported = post_rows(load_bundle(output_directory));
  const exported_by_slug = new Map(exported.map((row) => [row.slug, row]));
  const errors = [];
  for (const row of rows) {
    const actual = exported_by_slug.get(String(row.slug));
    if (!actual) {
      errors.push(`missing exported slug: ${row.slug}`);
      continue;
    }
    const expected = {
      title: String(row.title ?? ""),
      slug: String(row.slug ?? ""),
      excerpt: String(row.excerpt ?? ""),
      content: String(row.content ?? ""),
      slide_flag: Number(row.slide_flag) === 1 ? 1 : 0,
      status: String(row.status ?? "draft"),
      published_at: row.published_at === "" ? null : row.published_at ?? null,
      updated_at: String(row.updated_at ?? ""),
      visibility: String(row.visibility ?? "public"),
    };
    for (const key of Object.keys(expected)) {
      if (actual[key] !== expected[key]) {
        errors.push(`${row.slug}: ${key} changed during export (${expected[key]} -> ${actual[key]})`);
      }
    }
  }
  return errors;
}

export function parse_wrangler_json(output) {
  const parsed = JSON.parse(output);
  const results = Array.isArray(parsed) ? parsed.flatMap((entry) => entry.results ?? []) : parsed.results ?? [];
  return results;
}

function option_value(args, name) {
  const index = args.indexOf(name);
  return index >= 0 ? args[index + 1] : undefined;
}

export function fetch_posts(args = []) {
  const location = args.includes("--remote") ? "--remote" : "--local";
  const output = execFileSync(
    "pnpm",
    ["exec", "wrangler", "d1", "execute", "blog-db", location, "--command", QUERY, "--json"],
    { encoding: "utf8" },
  );
  return parse_wrangler_json(output);
}

function ensure_empty_output(directory) {
  if (!existsSync(directory)) {
    mkdirSync(directory, { recursive: true });
    return;
  }
  const entries = readdirSync(directory).filter((entry) => !entry.startsWith("."));
  if (entries.length > 0) throw new Error(`output directory is not empty: ${directory}`);
}

export function export_posts(rows, output_directory) {
  const root = resolve(output_directory);
  const slugs = new Set();
  for (const row of rows) {
    const slug = String(row.slug ?? "");
    if (!/^[A-Za-z0-9][A-Za-z0-9_-]*$/.test(slug)) {
      throw new Error(`slug cannot be used as an article filename: ${slug}`);
    }
    if (slugs.has(slug)) throw new Error(`duplicate slug: ${slug}`);
    slugs.add(slug);
  }
  ensure_empty_output(root);
  const articles = join(root, "articles");
  mkdirSync(articles, { recursive: true });
  writeFileSync(join(root, "index.md"), "# Knowledge\n\nGenerated from the blog D1 database.\n", "utf8");
  writeFileSync(join(root, "log.md"), "# Change Log\n\n- Initial D1 to OKF migration\n", "utf8");

  for (const row of rows) {
    const slug = String(row.slug ?? "");
    writeFileSync(join(articles, `${slug}.md`), render_article(row), "utf8");
  }
  return { output_directory: root, post_count: rows.length };
}

export function run_cli(args) {
  const output_directory = option_value(args, "--output-dir");
  if (!output_directory) throw new Error("pass --output-dir <directory>");
  const rows = fetch_posts(args);
  const result = export_posts(rows, output_directory);
  const errors = verify_round_trip(rows, output_directory);
  if (errors.length > 0) throw new Error(`round-trip verification failed:\n${errors.join("\n")}`);
  return { ...result, verified: true };
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    console.log(JSON.stringify(run_cli(process.argv.slice(2))));
  } catch (error) {
    console.error(JSON.stringify({ ok: false, error: error instanceof Error ? error.message : String(error) }));
    process.exitCode = 1;
  }
}

import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { execFileSync } from "node:child_process";
import { tmpdir } from "node:os";
import { extname, join, relative, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const POST_TYPES = new Set(["Blog Post", "Slide Deck"]);
const KNOWLEDGE_TYPES = new Set([
  "Blog Post",
  "Slide Deck",
  "Concept",
  "Decision",
  "Architecture",
  "Runbook",
  "Note",
  "Reference",
]);
const STATUSES = new Set(["draft", "published", "archived"]);
const VISIBILITIES = new Set(["private", "public"]);
const SLIDE_THEMES = new Set(["classic", "sunrise", "ocean"]);

export class OkfValidationError extends Error {
  constructor(errors) {
    super(errors.join("\n"));
    this.name = "OkfValidationError";
    this.errors = errors;
  }
}

function strip_inline_comment(value) {
  let quote = null;
  for (let index = 0; index < value.length; index += 1) {
    const character = value[index];
    if ((character === '"' || character === "'") && value[index - 1] !== "\\") {
      quote = quote === character ? null : quote ?? character;
    }
    if (character === "#" && quote === null && (index === 0 || /\s/.test(value[index - 1]))) {
      return value.slice(0, index).trim();
    }
  }
  return value.trim();
}

function parse_scalar(raw_value) {
  const value = strip_inline_comment(raw_value);
  if (value === "" || value === "null" || value === "~") return null;
  if (value === "true") return true;
  if (value === "false") return false;
  if (/^-?(?:0|[1-9]\d*)(?:\.\d+)?$/.test(value)) return Number(value);
  if (value.startsWith('"') && value.endsWith('"')) {
    try {
      return JSON.parse(value);
    } catch {
      return value.slice(1, -1);
    }
  }
  if (value.startsWith("'") && value.endsWith("'")) {
    return value.slice(1, -1).replaceAll("''", "'");
  }
  return value;
}

export function parse_front_matter(source, file_path = "<input>") {
  const normalized = source.replace(/^\uFEFF/, "").replaceAll("\r\n", "\n");
  if (!normalized.startsWith("---\n")) {
    throw new OkfValidationError([`${file_path}: missing YAML front matter`]);
  }

  const closing_marker = normalized.indexOf("\n---", 4);
  if (closing_marker < 0) {
    throw new OkfValidationError([`${file_path}: unterminated YAML front matter`]);
  }

  const closing_end = closing_marker + 4;
  const next_character = normalized[closing_end];
  if (next_character !== undefined && next_character !== "\n") {
    throw new OkfValidationError([`${file_path}: invalid YAML front matter closing marker`]);
  }

  const header = normalized.slice(4, closing_marker);
  let body_start = next_character === "\n" ? closing_end + 1 : closing_end;
  if (normalized[body_start] === "\n") body_start += 1;
  const body = normalized.slice(body_start);
  const metadata = {};

  for (const [line_number, line] of header.split("\n").entries()) {
    const trimmed = line.trim();
    if (trimmed === "" || trimmed.startsWith("#") || trimmed.startsWith("- ")) continue;
    if (/^\s/.test(line)) continue;
    const separator = line.indexOf(":");
    if (separator <= 0) {
      throw new OkfValidationError([
        `${file_path}:${line_number + 1}: invalid YAML front matter line`,
      ]);
    }
    const key = line.slice(0, separator).trim();
    if (!/^[A-Za-z0-9_-]+$/.test(key)) {
      throw new OkfValidationError([
        `${file_path}:${line_number + 1}: invalid top-level key`,
      ]);
    }
    metadata[key] = parse_scalar(line.slice(separator + 1));
  }

  return { metadata, body, header };
}

function walk_markdown_files(directory) {
  const files = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (entry.name.startsWith(".")) continue;
    const entry_path = join(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...walk_markdown_files(entry_path));
    } else if (entry.isFile() && extname(entry.name).toLowerCase() === ".md") {
      files.push(entry_path);
    }
  }
  return files.sort();
}

function string_value(metadata, key) {
  const value = metadata[key];
  return value === null || value === undefined ? "" : String(value);
}

function page_from_file(file_path, knowledge_dir) {
  const source = readFileSync(file_path, "utf8");
  const relative_path = relative(knowledge_dir, file_path).replaceAll("\\", "/");
  if (relative_path === "index.md" || relative_path === "log.md") {
    return { file_path, relative_path, source, metadata: null, body: source, special: true };
  }
  const parsed = parse_front_matter(source, relative_path);
  return { file_path, relative_path, source, ...parsed, special: false };
}

export function load_bundle(knowledge_dir) {
  const root = resolve(knowledge_dir);
  if (!existsSync(root) || !statSync(root).isDirectory()) {
    throw new OkfValidationError([`knowledge directory does not exist: ${root}`]);
  }
  for (const required_file of ["index.md", "log.md"]) {
    if (!existsSync(join(root, required_file))) {
      throw new OkfValidationError([`missing required OKF file: ${required_file}`]);
    }
  }
  const pages = walk_markdown_files(root).map((file_path) => page_from_file(file_path, root));
  return { root, pages };
}

function required_string(page, key, errors) {
  const value = string_value(page.metadata, key);
  if (value === "") errors.push(`${page.relative_path}: ${key} is required`);
  return value;
}

export function validate_bundle(bundle) {
  const errors = [];
  const slugs = new Map();

  for (const page of bundle.pages) {
    if (page.special) continue;
    const type = required_string(page, "type", errors);
    if (type === "") continue;
    if (!KNOWLEDGE_TYPES.has(type)) {
      errors.push(`${page.relative_path}: invalid type: ${type}`);
      continue;
    }

    if (!POST_TYPES.has(type)) continue;

    required_string(page, "title", errors);
    const slug = required_string(page, "slug", errors);
    const status = required_string(page, "status", errors);
    const visibility = required_string(page, "visibility", errors);

    if (status !== "" && !STATUSES.has(status)) {
      errors.push(`${page.relative_path}: invalid status: ${status}`);
    }
    if (visibility !== "" && !VISIBILITIES.has(visibility)) {
      errors.push(`${page.relative_path}: invalid visibility: ${visibility}`);
    }
    if (type === "Slide Deck") {
      const slide_theme = string_value(page.metadata, "slide_theme") || "classic";
      if (!SLIDE_THEMES.has(slide_theme)) {
        errors.push(`${page.relative_path}: invalid slide_theme: ${slide_theme}`);
      }
    }
    if (slug !== "") {
      if (!/^[A-Za-z0-9][A-Za-z0-9_-]*$/.test(slug)) {
        errors.push(`${page.relative_path}: invalid slug: ${slug}`);
      }
      const previous = slugs.get(slug);
      if (previous) {
        errors.push(`${page.relative_path}: duplicate slug ${slug} (also ${previous})`);
      } else {
        slugs.set(slug, page.relative_path);
      }
    }

    const timestamp = page.metadata.timestamp ?? page.metadata.updated_at;
    if (timestamp === undefined || timestamp === null || String(timestamp).trim() === "") {
      errors.push(`${page.relative_path}: timestamp or updated_at is required`);
    }
  }

  return errors;
}

function sql_string(value) {
  return `'${String(value).replaceAll("'", "''")}'`;
}

function sql_value(value) {
  if (value === null || value === undefined || value === "") return "NULL";
  return sql_string(value);
}

function post_from_page(page) {
  const metadata = page.metadata;
  const type = string_value(metadata, "type");
  const description = metadata.description ?? metadata.excerpt ?? "";
  const timestamp = metadata.timestamp ?? metadata.updated_at;
  const content =
    type === "Slide Deck" && !page.body.startsWith("---\n")
      ? `---\nslide_theme: ${string_value(metadata, "slide_theme") || "classic"}\n---\n\n${page.body}`
      : page.body;
  return {
    title: string_value(metadata, "title"),
    slug: string_value(metadata, "slug"),
    excerpt: description === null ? "" : String(description),
    content,
    slide_flag: type === "Slide Deck" ? 1 : 0,
    status: string_value(metadata, "status"),
    published_at: metadata.published_at ?? null,
    updated_at: String(timestamp),
    visibility: string_value(metadata, "visibility"),
  };
}

export function post_rows(bundle) {
  const errors = validate_bundle(bundle);
  if (errors.length > 0) throw new OkfValidationError(errors);
  return bundle.pages.filter((page) => !page.special && POST_TYPES.has(string_value(page.metadata, "type"))).map(post_from_page);
}

export function generate_sync_sql(bundle) {
  const rows = post_rows(bundle);
  const statements = ["BEGIN TRANSACTION;"];
  for (const row of rows) {
    statements.push(
      [
        "INSERT INTO posts (title, slug, excerpt, content, slide_flag, status, published_at, updated_at, visibility)",
        `VALUES (${sql_string(row.title)}, ${sql_string(row.slug)}, ${sql_value(row.excerpt)}, ${sql_string(row.content)}, ${row.slide_flag}, ${sql_string(row.status)}, ${sql_value(row.published_at)}, ${sql_string(row.updated_at)}, ${sql_string(row.visibility)})`,
        "ON CONFLICT(slug) DO UPDATE SET",
        "title = excluded.title,",
        "excerpt = excluded.excerpt,",
        "content = excluded.content,",
        "slide_flag = excluded.slide_flag,",
        "status = excluded.status,",
        "published_at = excluded.published_at,",
        "updated_at = excluded.updated_at,",
        "visibility = excluded.visibility;",
      ].join("\n"),
    );
  }
  if (rows.length === 0) {
    statements.push("DELETE FROM posts;");
  } else {
    const slugs = rows.map((row) => sql_string(row.slug)).join(", ");
    statements.push(`DELETE FROM posts WHERE slug NOT IN (${slugs});`);
  }
  statements.push("COMMIT;");
  return `${statements.join("\n\n")}\n`;
}

export function sync_local_database(bundle) {
  const sql = generate_sync_sql(bundle);
  const temporary_directory = join(tmpdir(), `blog-okf-${process.pid}-${Date.now()}`);
  const sql_path = join(temporary_directory, "sync.sql");
  mkdirSync(temporary_directory, { recursive: true });
  writeFileSync(sql_path, sql, "utf8");
  try {
    execFileSync("pnpm", ["exec", "wrangler", "d1", "execute", "blog-db", "--local", "--file", sql_path], {
      stdio: "inherit",
    });
  } finally {
    rmSync(temporary_directory, { recursive: true, force: true });
  }
  return { post_count: post_rows(bundle).length };
}

function option_value(args, name) {
  const index = args.indexOf(name);
  return index >= 0 ? args[index + 1] : undefined;
}

function knowledge_directory(args) {
  return option_value(args, "--knowledge-dir") ?? process.env.BLOG_KNOWLEDGE_DIR;
}

export function run_cli(args) {
  const command = args[0] ?? "validate";
  const directory = knowledge_directory(args);
  if (!directory) {
    throw new OkfValidationError(["set BLOG_KNOWLEDGE_DIR or pass --knowledge-dir"]);
  }
  const bundle = load_bundle(directory);
  const errors = validate_bundle(bundle);
  if (errors.length > 0) throw new OkfValidationError(errors);

  if (command === "validate") {
    return { command, ok: true, knowledge_dir: bundle.root, post_count: post_rows(bundle).length };
  }
  if (command === "sync") {
    if (args.includes("--dry-run")) {
      return { command, ok: true, dry_run: true, knowledge_dir: bundle.root, post_count: post_rows(bundle).length, sql: generate_sync_sql(bundle) };
    }
    return { command, ok: true, knowledge_dir: bundle.root, ...sync_local_database(bundle) };
  }
  throw new OkfValidationError([`unknown command: ${command}`]);
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    const result = run_cli(process.argv.slice(2));
    console.log(JSON.stringify(result));
  } catch (error) {
    const errors = error instanceof OkfValidationError ? error.errors : [error instanceof Error ? error.message : String(error)];
    console.error(JSON.stringify({ ok: false, errors }));
    process.exitCode = 1;
  }
}

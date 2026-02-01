import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const root = resolve(new URL(".", import.meta.url).pathname, "..");
const configPath = resolve(root, "config", "blog.toml");
const outputPath = resolve(root, "src", "config", "site_config.mbt");

function parseTomlFlat(input) {
  const result = {};
  const lines = input.split(/\r?\n/);
  for (const raw of lines) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }
    const eq = line.indexOf("=");
    if (eq === -1) {
      continue;
    }
    const key = line.slice(0, eq).trim();
    let value = line.slice(eq + 1).trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.slice(1, -1);
    }
    result[key] = value;
  }
  return result;
}

const toml = readFileSync(configPath, "utf8");
const config = parseTomlFlat(toml);

const siteTitle = config.site_title ?? "MoonBit Blog";
const footerText =
  config.footer_text ?? "Built with MoonBit, TMPX, MHX, and Cloudflare Workers";
const siteUrl = config.site_url ?? "https://example.com";
const siteName = config.site_name ?? siteTitle;
const siteDescription = config.site_description ?? "";
const defaultOgImage = config.default_og_image ?? "/static/ogp-default.png";

const output = `///|
/// Auto-generated from config/blog.toml. Do not edit by hand.
pub const SITE_TITLE : String = "${siteTitle.replace(/"/g, '\\"')}"\n
///|
/// Auto-generated from config/blog.toml. Do not edit by hand.
pub const FOOTER_TEXT : String = "${footerText.replace(/"/g, '\\"')}"\n
///|
/// Site URL for generating absolute URLs (canonical links, OGP images, etc.)
pub const SITE_URL : String = "${siteUrl.replace(/"/g, '\\"')}"\n
///|
/// Site name for OGP tags (og:site_name)
pub const SITE_NAME : String = "${siteName.replace(/"/g, '\\"')}"\n
///|
/// Site description for meta tags and OGP
pub const SITE_DESCRIPTION : String = "${siteDescription.replace(/"/g, '\\"')}"\n
///|
/// Default OGP image path (relative to SITE_URL, or absolute URL)
pub const DEFAULT_OG_IMAGE : String = "${defaultOgImage.replace(/"/g, '\\"')}"\n`;

writeFileSync(outputPath, output);

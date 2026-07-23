import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const default_bundle_path = "dist/blog/index.js";

const global_seed_declaration = "var _M0FPB4seed = _M0FPB12random__seed();";
const lazy_seed_declaration = `var _M0FPB4seed = 0;
var _M0FPB4seed_initialized = false;
function _M0FPB4get_seed() {
\tif (!_M0FPB4seed_initialized) {
\t\t_M0FPB4seed = _M0FPB12random__seed();
\t\t_M0FPB4seed_initialized = true;
\t}
\treturn _M0FPB4seed;
}`;
const eager_seed_use = "(_M0FPB4seed >>> 0)";
const lazy_seed_use = "(_M0FPB4get_seed() >>> 0)";

export function patch_worker_bundle(source) {
  const declaration_count = source.split(global_seed_declaration).length - 1;
  if (declaration_count !== 1) {
    throw new Error(`expected one MoonBit global hasher seed declaration, found ${declaration_count}`);
  }

  const seed_use_count = source.split(eager_seed_use).length - 1;
  if (seed_use_count === 0) {
    throw new Error("expected at least one MoonBit hasher seed use");
  }

  return source.replace(global_seed_declaration, lazy_seed_declaration).replaceAll(eager_seed_use, lazy_seed_use);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const bundle_path = process.argv[2] ?? default_bundle_path;
  const source = readFileSync(bundle_path, "utf8");
  writeFileSync(bundle_path, patch_worker_bundle(source));
  console.log(`patched Cloudflare-safe MoonBit hasher initialization: ${bundle_path}`);
}

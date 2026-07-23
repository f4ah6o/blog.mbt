import { spawn } from "node:child_process";
import { watch } from "node:fs";
import { resolve } from "node:path";

import { OkfValidationError, run_cli } from "./okf_content.mjs";

const knowledge_dir = process.env.BLOG_KNOWLEDGE_DIR;

function format_error(error) {
  if (error instanceof OkfValidationError) return error.errors.join("\n");
  return error instanceof Error ? error.message : String(error);
}

function sync_content() {
  try {
    const result = run_cli(["sync", "--knowledge-dir", knowledge_dir]);
    console.log(`[preview] synced ${result.post_count} site articles`);
    return true;
  } catch (error) {
    console.error(`[preview] content sync failed:\n${format_error(error)}`);
    return false;
  }
}

if (!knowledge_dir) {
  console.error("[preview] set BLOG_KNOWLEDGE_DIR to the OKF bundle directory");
  process.exit(1);
}

const resolved_knowledge_dir = resolve(knowledge_dir);
if (!sync_content()) process.exit(1);

const child = spawn("pnpm", ["exec", "vp", "dev"], {
  env: {
    ...process.env,
    BLOG_KNOWLEDGE_DIR: resolved_knowledge_dir,
    BLOG_PREVIEW_DRAFTS: "true",
    CLOUDFLARE_INCLUDE_PROCESS_ENV: "true",
  },
  stdio: "inherit",
});

let sync_timer = null;
function schedule_sync() {
  if (sync_timer !== null) clearTimeout(sync_timer);
  sync_timer = setTimeout(() => {
    sync_timer = null;
    sync_content();
  }, 200);
}

const watcher = watch(resolved_knowledge_dir, { recursive: true }, schedule_sync);
let shutting_down = false;

function shutdown(signal) {
  if (shutting_down) return;
  shutting_down = true;
  watcher.close();
  if (sync_timer !== null) clearTimeout(sync_timer);
  child.kill(signal);
}

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));

child.on("error", (error) => {
  console.error(`[preview] failed to start Vite: ${error.message}`);
  process.exitCode = 1;
});

child.on("exit", (code, signal) => {
  watcher.close();
  if (shutting_down) {
    process.exitCode = 0;
  } else if (signal) {
    process.exitCode = 1;
  } else {
    process.exitCode = code ?? 1;
  }
});

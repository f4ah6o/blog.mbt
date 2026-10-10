import { spawn } from "node:child_process";
import { mkdtempSync, openSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

// cf helpers for the BLOG_DB D1 binding.
//
// cf resource commands take the database ID, not the name. Local commands
// (`cf d1 raw --local`) use the ID as the durable-object name of the local
// database simulation, so they only see the dev server's data when both the
// `--persist-to` directory and the ID match what `vp dev` uses
// (`.cloudflare/state` + the `id` configured on the BLOG_DB binding).
// The ID is resolved from cloudflare.config.ts at runtime so the real
// database UUID never has to be committed.

const root = resolve(new URL(".", import.meta.url).pathname, "..");
const LOCAL_PERSIST_DIR = resolve(root, ".cloudflare", "state");

export function d1_binding(config_path = resolve(root, "cloudflare.config.ts"), mode) {
	const source = readFileSync(config_path, "utf8");
	// Find the requested `case "<mode>"` block (or `default:`) and read the
	// BLOG_DB binding inside it. The default block holds the production/local
	// dev binding that `vp dev` uses.
	const marker = mode === undefined ? "default:" : `case "${mode}":`;
	const start = source.indexOf(marker);
	if (start === -1) throw new Error(`cloudflare.config.ts: no ${marker} block`);
	const binding_start = source.indexOf("BLOG_DB:", start);
	if (binding_start === -1) throw new Error(`cloudflare.config.ts: no BLOG_DB binding after ${marker}`);
	const window = source.slice(binding_start, binding_start + 400);
	const name = window.match(/name:\s*"([^"]+)"/)?.[1];
	const id = window.match(/id:\s*"([^"]+)"/)?.[1];
	return { name, id };
}

const CF_BIN = resolve(root, "node_modules", ".bin", "cf");
const CF_TIMEOUT_MS = 120_000;

function complete_json(text) {
	if (!/^\s*[\[{]/.test(text)) return false;
	try {
		JSON.parse(text);
		return true;
	} catch {
		return false;
	}
}

function alive(pid) {
	try {
		process.kill(pid, 0);
		return true;
	} catch {
		return false;
	}
}

// `cf d1 raw --local` spawns a miniflare simulation whose file watcher can
// keep the cf event loop alive after the query result was already written to
// stdout. Redirect stdout to a file and poll it (no event-loop involvement)
// until a complete JSON envelope arrived; kill cf at the timeout.
function cf(args) {
	const out_dir = mkdtempSync(join(tmpdir(), "cf-out-"));
	const out_path = join(out_dir, "stdout.json");
	const err_path = join(out_dir, "stderr.txt");
	const out_fd = openSync(out_path, "w+");
	const err_fd = openSync(err_path, "w+");
	const child = spawn(CF_BIN, args, {
		cwd: root,
		stdio: ["ignore", out_fd, err_fd],
		detached: true,
	});
	const signal = new Int32Array(new SharedArrayBuffer(4));
	const deadline = Date.now() + CF_TIMEOUT_MS;
	const output = () => readFileSync(out_path, "utf8");
	const errors = () => readFileSync(err_path, "utf8");
	// a finished error box (last line `└`) means cf reported a failure and will
	// not print a result envelope; stop waiting for stdout
	const failed = () => /^└/m.test(errors());
	try {
		while (alive(child.pid) && Date.now() < deadline && !complete_json(output()) && !failed()) {
			Atomics.wait(signal, 0, 0, 50);
		}
	} finally {
		if (alive(child.pid)) {
			try {
				process.kill(-child.pid, "SIGKILL");
			} catch {
				try {
					child.kill("SIGKILL");
				} catch {}
			}
		}
	}
	const text = output();
	const err = errors();
	rmSync(out_dir, { recursive: true, force: true });
	if (!complete_json(text)) {
		const detail = err.trim().split("\n").slice(-6).join("\n");
		throw new Error(`cf ${args.join(" ")} produced no JSON result${detail ? `:\n${detail}` : ""}`);
	}
	return text;
}

export function run_local_d1(sql) {
	const { id } = d1_binding();
	if (!id) throw new Error("BLOG_DB binding has no `id` in cloudflare.config.ts");
	// equals form: SQL content can start with a `--` comment, which yargs
	// would otherwise treat as an argument separator
	return cf(["d1", "raw", id, "--local", "--persist-to", LOCAL_PERSIST_DIR, `--sql=${sql}`]);
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function resolve_remote_d1_id() {
	const { name, id } = d1_binding();
	if (id && UUID_RE.test(id)) return id;
	// The configured id is a placeholder: look the real ID up by database name.
	const output = cf(["d1", "list"]);
	const entries = JSON.parse(output);
	const list = Array.isArray(entries) ? entries : (entries.result ?? entries.databases ?? []);
	const match = list.find((entry) => entry.name === name);
	const remote_id = match?.uuid ?? match?.id;
	if (!remote_id) throw new Error(`cf d1 list: no database named ${name}`);
	return remote_id;
}

export function run_remote_d1(sql) {
	return cf(["d1", "query", resolve_remote_d1_id(), `--sql=${sql}`]);
}

// `cf d1 raw` returns rows as arrays with a separate `columns` list;
// `cf d1 query` returns rows as objects. Both wrap results in a top-level
// array of statement results. Normalize to an array of row objects.
export function parse_cf_d1_json(output) {
	const parsed = JSON.parse(output);
	const entries = Array.isArray(parsed) ? parsed : [parsed];
	const rows = [];
	for (const entry of entries) {
		const results = entry.results ?? entry.result?.results ?? [];
		if (Array.isArray(results)) {
			rows.push(...results);
		} else if (results && Array.isArray(results.rows)) {
			const columns = results.columns ?? [];
			for (const row of results.rows) {
				rows.push(Object.fromEntries(columns.map((column, index) => [column, row[index]])));
			}
		}
	}
	return rows;
}

function option_value(args, name) {
	const index = args.indexOf(name);
	if (index >= 0) return args[index + 1];
	const prefix = `${name}=`;
	return args.find((arg) => arg.startsWith(prefix))?.slice(prefix.length);
}

export function run_cli(args) {
	const location = args.includes("--remote") ? "--remote" : "--local";
	const file = option_value(args, "--file");
	const sql = file ? readFileSync(resolve(root, file), "utf8") : option_value(args, "--sql");
	if (!sql) throw new Error("pass --file <path> or --sql <statement>");
	const output = location === "--remote" ? run_remote_d1(sql) : run_local_d1(sql);
	if (output) process.stdout.write(output);
	return { location };
}

if (process.argv[1] && import.meta.url === new URL(`file://${resolve(process.argv[1])}`).href) {
	try {
		run_cli(process.argv.slice(2));
	} catch (error) {
		console.error(JSON.stringify({ ok: false, error: error instanceof Error ? error.message : String(error) }));
		process.exitCode = 1;
	}
}

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

const schemaSql = readFileSync(new URL("../schema.sql", import.meta.url), "utf8");
const oauthMigrationSql = readFileSync(
  new URL("../migrate_oauth_v01.sql", import.meta.url),
  "utf8",
);

let DatabaseSync;
try {
  ({ DatabaseSync } = await import("node:sqlite"));
} catch {
  DatabaseSync = undefined;
}

const skip =
  DatabaseSync === undefined
    ? "node:sqlite is unavailable in this Node runtime"
    : false;

function tableNames(db) {
  return db
    .prepare("SELECT name FROM sqlite_master WHERE type = 'table'")
    .all()
    .map((row) => row.name);
}

test("schema.sql creates the pending authorization table", { skip }, () => {
  const db = new DatabaseSync(":memory:");
  try {
    db.exec(schemaSql);
    assert.ok(tableNames(db).includes("oauth_pending_authorizations"));
  } finally {
    db.close();
  }
});

test("migrate_oauth_v01.sql adds pending authorizations and is idempotent", { skip }, () => {
  const db = new DatabaseSync(":memory:");
  try {
    db.exec(oauthMigrationSql);
    assert.ok(tableNames(db).includes("oauth_pending_authorizations"));
    db.exec(oauthMigrationSql);
    assert.ok(tableNames(db).includes("oauth_pending_authorizations"));
  } finally {
    db.close();
  }
});

test("migrate_oauth_v01.sql upgrades a database that predates the pending table", { skip }, () => {
  const db = new DatabaseSync(":memory:");
  try {
    db.exec(oauthMigrationSql);
    db.exec("DROP TABLE oauth_pending_authorizations");
    assert.ok(!tableNames(db).includes("oauth_pending_authorizations"));
    db.exec(oauthMigrationSql);
    const tables = tableNames(db);
    assert.ok(tables.includes("oauth_authorization_codes"));
    assert.ok(tables.includes("oauth_pending_authorizations"));
  } finally {
    db.close();
  }
});

test("pending authorization claim is a single-use conditional update", { skip }, () => {
  const db = new DatabaseSync(":memory:");
  try {
    db.exec(oauthMigrationSql);
    db.prepare(
      "INSERT INTO oauth_pending_authorizations (challenge_id, user_id, client_id, redirect_uri, resource, scope, code_challenge, code_challenge_method, state, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    ).run(
      "challenge-1",
      "user-1",
      "https://client.example/client.json",
      "https://client.example/callback",
      "https://blog.example/mcp",
      "blog:read",
      "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
      "S256",
      "opaque-state",
      100,
      400,
    );
    const claim = db.prepare(
      "UPDATE oauth_pending_authorizations SET consumed_at = ? WHERE challenge_id = ? AND user_id = ? AND expires_at > ? AND consumed_at IS NULL",
    );
    assert.equal(Number(claim.run(200, "challenge-1", "user-1", 200).changes), 1);
    assert.equal(Number(claim.run(201, "challenge-1", "user-1", 201).changes), 0);
    assert.equal(Number(claim.run(500, "challenge-1", "user-1", 500).changes), 0);
  } finally {
    db.close();
  }
});

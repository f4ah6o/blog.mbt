import assert from "node:assert/strict";
import { createHash } from "node:crypto";
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
    assert.ok(tableNames(db).includes("oauth_authorization_codes"));
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

test("authorization-code issuance stores only the hash and exact bindings", { skip }, () => {
  const db = new DatabaseSync(":memory:");
  try {
    db.exec(oauthMigrationSql);
    const rawCode = "deterministic-authorization-code";
    const codeHash = createHash("sha256").update(rawCode).digest("hex");
    const createdAt = 1_700_000_000;
    db.prepare(
      "INSERT INTO oauth_authorization_codes (code_hash, client_id, redirect_uri, resource, scope, code_challenge, code_challenge_method, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
    ).run(
      codeHash,
      "https://client.example/client.json",
      "https://client.example/callback?tenant=one",
      "https://blog.example/mcp",
      "blog:read offline_access",
      "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
      "S256",
      createdAt,
      createdAt + 60,
    );

    const columns = db
      .prepare("PRAGMA table_info(oauth_authorization_codes)")
      .all()
      .map((row) => row.name);
    assert.ok(columns.includes("code_hash"));
    assert.ok(!columns.includes("code"));
    const row = db
      .prepare(
        "SELECT code_hash, client_id, redirect_uri, resource, scope, code_challenge, code_challenge_method, created_at, expires_at, consumed_at FROM oauth_authorization_codes",
      )
      .get();
    assert.deepEqual({ ...row }, {
      code_hash: codeHash,
      client_id: "https://client.example/client.json",
      redirect_uri: "https://client.example/callback?tenant=one",
      resource: "https://blog.example/mcp",
      scope: "blog:read offline_access",
      code_challenge: "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
      code_challenge_method: "S256",
      created_at: createdAt,
      expires_at: createdAt + 60,
      consumed_at: null,
    });
    assert.notEqual(row.code_hash, rawCode);
    assert.equal(row.expires_at - row.created_at, 60);
  } finally {
    db.close();
  }
});

test("authorization-code redemption is conditional and single-use", { skip }, () => {
  const db = new DatabaseSync(":memory:");
  try {
    db.exec(oauthMigrationSql);
    const codeHash = createHash("sha256")
      .update("deterministic-authorization-code")
      .digest("hex");
    db.prepare(
      "INSERT INTO oauth_authorization_codes (code_hash, client_id, redirect_uri, resource, scope, code_challenge, code_challenge_method, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
    ).run(
      codeHash,
      "https://client.example/client.json",
      "https://client.example/callback",
      "https://blog.example/mcp",
      "blog:read",
      "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
      "S256",
      1_700_000_000,
      1_700_000_060,
    );

    const claim = db.prepare(
      "UPDATE oauth_authorization_codes SET consumed_at = ? WHERE code_hash = ? AND client_id = ? AND redirect_uri = ? AND resource = ? AND code_challenge = ? AND code_challenge_method = 'S256' AND expires_at > ? AND consumed_at IS NULL",
    );
    const wrongBinding = claim.run(
      1_700_000_010,
      codeHash,
      "https://client.example/client.json",
      "https://client.example/other",
      "https://blog.example/mcp",
      "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
      1_700_000_010,
    );
    assert.equal(Number(wrongBinding.changes), 0);

    const firstClaim = claim.run(
      1_700_000_010,
      codeHash,
      "https://client.example/client.json",
      "https://client.example/callback",
      "https://blog.example/mcp",
      "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
      1_700_000_010,
    );
    assert.equal(Number(firstClaim.changes), 1);
    const replay = claim.run(
      1_700_000_011,
      codeHash,
      "https://client.example/client.json",
      "https://client.example/callback",
      "https://blog.example/mcp",
      "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
      1_700_000_011,
    );
    assert.equal(Number(replay.changes), 0);
    assert.equal(
      db
        .prepare("SELECT consumed_at FROM oauth_authorization_codes WHERE code_hash = ?")
        .get(codeHash).consumed_at,
      1_700_000_010,
    );
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

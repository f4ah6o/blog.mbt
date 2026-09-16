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

test("authorization-code exchange gates token inserts on the same one-time claim", { skip }, () => {
  const db = new DatabaseSync(":memory:");
  try {
    db.exec(oauthMigrationSql);
    const codeHash = createHash("sha256")
      .update("atomic-authorization-code")
      .digest("hex");
    const accessHash = createHash("sha256").update("atomic-access").digest("hex");
    const refreshHash = createHash("sha256").update("atomic-refresh").digest("hex");
    const clientId = "https://client.example/client.json";
    const redirectUri = "https://client.example/callback";
    const resource = "https://blog.example/mcp";
    const scope = "blog:read offline_access";
    const challenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM";
    db.prepare(
      "INSERT INTO oauth_authorization_codes (code_hash, client_id, redirect_uri, resource, scope, code_challenge, code_challenge_method, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, 'S256', ?, ?)",
    ).run(codeHash, clientId, redirectUri, resource, scope, challenge, 100, 160);

    const claim = db.prepare(
      "UPDATE oauth_authorization_codes SET consumed_at = ? WHERE code_hash = ? AND client_id = ? AND redirect_uri = ? AND resource = ? AND scope = ? AND code_challenge = ? AND code_challenge_method = 'S256' AND expires_at > ? AND consumed_at IS NULL",
    );
    const accessInsert = db.prepare(
      "INSERT INTO oauth_access_tokens (token_hash, client_id, resource, scope, created_at, expires_at) SELECT ?, ?, ?, ?, ?, ? WHERE changes() = 1 AND EXISTS (SELECT 1 FROM oauth_authorization_codes WHERE code_hash = ? AND client_id = ? AND redirect_uri = ? AND resource = ? AND scope = ? AND code_challenge = ? AND consumed_at = ?)",
    );
    const refreshInsert = db.prepare(
      "INSERT INTO oauth_refresh_tokens (token_hash, family_hash, client_id, resource, scope, created_at, expires_at) SELECT ?, ?, ?, ?, ?, ?, ? WHERE changes() = 1 AND EXISTS (SELECT 1 FROM oauth_authorization_codes WHERE code_hash = ? AND client_id = ? AND redirect_uri = ? AND resource = ? AND scope = ? AND code_challenge = ? AND consumed_at = ?)",
    );

    db.exec("BEGIN");
    assert.equal(Number(claim.run(110, codeHash, clientId, redirectUri, resource, scope, challenge, 110).changes), 1);
    assert.equal(Number(accessInsert.run(accessHash, clientId, resource, scope, 110, 3710, codeHash, clientId, redirectUri, resource, scope, challenge, 110).changes), 1);
    assert.equal(Number(refreshInsert.run(refreshHash, refreshHash, clientId, resource, scope, 110, 2_592_110, codeHash, clientId, redirectUri, resource, scope, challenge, 110).changes), 1);
    db.exec("COMMIT");

    const replayAccessHash = createHash("sha256").update("replay-access").digest("hex");
    db.exec("BEGIN");
    assert.equal(Number(claim.run(110, codeHash, clientId, redirectUri, resource, scope, challenge, 110).changes), 0);
    assert.equal(Number(accessInsert.run(replayAccessHash, clientId, resource, scope, 110, 3711, codeHash, clientId, redirectUri, resource, scope, challenge, 110).changes), 0);
    assert.equal(Number(refreshInsert.run(createHash("sha256").update("replay-refresh").digest("hex"), createHash("sha256").update("replay-refresh").digest("hex"), clientId, resource, scope, 110, 2_592_110, codeHash, clientId, redirectUri, resource, scope, challenge, 110).changes), 0);
    db.exec("COMMIT");
    assert.equal(db.prepare("SELECT COUNT(*) AS count FROM oauth_access_tokens").get().count, 1);
    assert.equal(db.prepare("SELECT COUNT(*) AS count FROM oauth_refresh_tokens").get().count, 1);
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

test("access and refresh rows store hashes and rotate refresh tokens once", { skip }, () => {
  const db = new DatabaseSync(":memory:");
  try {
    db.exec(oauthMigrationSql);
    const rawAccess = "access-secret-not-persisted";
    const rawRefresh = "refresh-secret-not-persisted";
    const accessHash = createHash("sha256").update(rawAccess).digest("hex");
    const refreshHash = createHash("sha256").update(rawRefresh).digest("hex");
    const familyHash = refreshHash;
    const clientId = "https://client.example/client.json";
    const resource = "https://blog.example/mcp";
    const scope = "blog:read offline_access";
    db.prepare(
      "INSERT INTO oauth_access_tokens (token_hash, client_id, resource, scope, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?)",
    ).run(accessHash, clientId, resource, scope, 100, 3700);
    db.prepare(
      "INSERT INTO oauth_refresh_tokens (token_hash, family_hash, client_id, resource, scope, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
    ).run(refreshHash, familyHash, clientId, resource, scope, 100, 100 + 30 * 24 * 60 * 60);
    const replacementHash = createHash("sha256").update("replacement").digest("hex");
    const update = db.prepare(
      "UPDATE oauth_refresh_tokens SET consumed_at = ?, replacement_token_hash = ? WHERE token_hash = ? AND client_id = ? AND resource = ? AND expires_at > ? AND consumed_at IS NULL AND revoked_at IS NULL",
    );
    assert.equal(Number(update.run(200, replacementHash, refreshHash, clientId, resource, 200).changes), 1);
    db.prepare(
      "INSERT INTO oauth_refresh_tokens (token_hash, family_hash, client_id, resource, scope, created_at, expires_at) SELECT ?, family_hash, client_id, resource, scope, ?, ? FROM oauth_refresh_tokens WHERE token_hash = ? AND consumed_at = ? AND replacement_token_hash = ?",
    ).run(replacementHash, 200, 200 + 30 * 24 * 60 * 60, refreshHash, 200, replacementHash);
    const replacementAccessHash = createHash("sha256").update("replacement-access").digest("hex");
    const replacementAccessInsert = db.prepare(
      "INSERT INTO oauth_access_tokens (token_hash, client_id, resource, scope, created_at, expires_at) SELECT ?, client_id, resource, scope, ?, ? FROM oauth_refresh_tokens WHERE token_hash = ? AND client_id = ? AND resource = ? AND consumed_at = ? AND replacement_token_hash = ?",
    );
    assert.equal(Number(replacementAccessInsert.run(replacementAccessHash, 200, 3800, refreshHash, clientId, resource, 200, replacementHash).changes), 1);
    const replacementAccess = db
      .prepare("SELECT client_id, resource, scope FROM oauth_access_tokens WHERE token_hash = ?")
      .get(replacementAccessHash);
    assert.equal(replacementAccess.client_id, clientId);
    assert.equal(replacementAccess.resource, resource);
    assert.equal(replacementAccess.scope, scope);
    assert.notEqual(db.prepare("SELECT token_hash FROM oauth_access_tokens").get().token_hash, rawAccess);
    assert.notEqual(db.prepare("SELECT token_hash FROM oauth_refresh_tokens WHERE token_hash = ?").get(refreshHash).token_hash, rawRefresh);
    const replayHash = createHash("sha256").update("replay").digest("hex");
    assert.equal(Number(update.run(201, replayHash, refreshHash, clientId, resource, 201).changes), 0);
    assert.equal(Number(replacementAccessInsert.run(createHash("sha256").update("replay-access").digest("hex"), 201, 3801, refreshHash, clientId, resource, 201, replayHash).changes), 0);
    db.prepare(
      "UPDATE oauth_refresh_tokens SET revoked_at = ? WHERE family_hash = (SELECT family_hash FROM oauth_refresh_tokens WHERE token_hash = ? AND client_id = ? AND resource = ?) AND revoked_at IS NULL",
    ).run(201, refreshHash, clientId, resource);
    assert.equal(db.prepare("SELECT COUNT(*) AS count FROM oauth_refresh_tokens WHERE family_hash = ? AND revoked_at IS NOT NULL").get(familyHash).count, 2);
    assert.equal(db.prepare("SELECT COUNT(*) AS count FROM oauth_access_tokens").get().count, 2);
  } finally {
    db.close();
  }
});

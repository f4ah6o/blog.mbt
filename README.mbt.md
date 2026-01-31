# MoonBit Blog

MoonBit + Cloudflare Workers + D1 のシンプルなブログです。

## Quick Start

```bash
just build
just init-db
just seed-db
just dev
```

`http://localhost:8787` で確認できます。

## 記事の書き方

記事は D1 の `posts` テーブルに保存されます。ローカルでは以下どちらかで追加できます。

### 1) SQL を直接実行する（おすすめ）

```bash
npx wrangler d1 execute blog-db --local --command \
  "INSERT INTO posts (title, slug, excerpt, content, published_at, updated_at)
   VALUES ('My Post', 'my-post', 'short excerpt', 'full content',
           '2026-01-31T00:00:00Z', '2026-01-31T00:00:00Z');"
```

### 2) seed.sql を流す

```bash
just seed-db
```

## 本番デプロイ時の DB

本番では **schema.sql のみ** を適用し、seed は流さないでください。

```bash
npx wrangler d1 execute blog-db --file=schema.sql
```

## D1 利用時の制約（重要）

Cloudflare Worker の fetch handler 直下で `D1PreparedStatement::first_col` など
MoonBit の async API を使うと `$panic` になることがあります
（内部で `Promise.wait()` がコルーチン外で呼ばれるため）。

このため、`src/worker/main.mbt` では **JS extern で D1 を叩く**形にしています。
同様の処理を追加するときは、以下の方針を守ってください。

- Worker 入口では JS Promise を返す（`extern "js"` + `.then(...)`）
- MoonBit 側の `D1PreparedStatement::first_col`/`first`/`all` を直接呼ばない

## MHX の読み込み

`static/mhx.js` を配信しているので、HTML では次のように読み込まれます。

```html
<script src="/mhx.js" defer></script>
```

## サイト設定

ブログのタイトルやフッター文言は `config/blog.toml` で管理します。
変更後は `just gen-config` または `just build` を実行してください。

注意: 現在の TOML パーサはフラットな `key = "value"` のみ対応しています。

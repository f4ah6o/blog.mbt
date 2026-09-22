# MoonBit Blog

MoonBit + Cloudflare Workers + D1 で構築されたシンプルなブログシステムです。

WebAuthn によるセキュアな管理者認証と、型安全な TMPX テンプレートエンジンを特徴とします。

## Quick Start

```bash
just local
```

これでビルド、データベース初期化、シードデータ投入、開発サーバー起動が一括で行われます。
`http://localhost:8787` で確認できます。

## コマンドリファレンス

### 開発

```bash
just local        # 完全なローカル開発環境をセットアップ（build + init-db + seed-db + dev）
just preview      # OKF MarkdownをD1へ同期して、保存時に更新するPreviewを起動
just dev          # ローカル開発サーバー起動
just build        # Cloudflare Workers 向けにビルド
just fmt          # コードフォーマット
just check        # 型チェック
just test         # テスト実行
just test-update  # スナップショットテストを更新
```

### データベース

```bash
just init-db      # ローカル D1 データベースを初期化（schema.sql 適用）
just migrate-db   # ローカル DB を v0.4 スキーマにマイグレーション
just seed-db      # シードデータを投入
```

### OKF Markdown Preview

記事の正本を別リポジトリのOKF bundleに置く場合は、そのディレクトリを指定してPreviewを起動します。`Blog Post` と `Slide Deck` だけがD1へ投影され、`Concept` や `Decision` などの知識ページは投影されません。

```bash
export BLOG_KNOWLEDGE_DIR=/path/to/private-knowledge
just content-check
just preview
```

Previewでは `draft`、`published`、`archived` を確認できますが、RSSなどの公開向けルートは `published` かつ `public` の記事だけを返します。既存D1記事の初回移行には、空の出力先へ `just content-export /path/to/private-knowledge` を使えます。リモートD1を読み出す場合は `just content-export /path/to/private-knowledge --remote` とします。

### デプロイ

```bash
just deploy       # Cloudflare Workers にデプロイ（1Passwordでシークレットを設定）
just deploy-local # Cloudflare Workers にデプロイ（ローカル環境変数を使用）
just deploy-db    # 本番 D1 データベースを初期化
just deploy-migrate-db  # 本番 DB をマイグレーション
```

### その他

```bash
just gen-config   # blog.toml から設定コードを生成
just info         # 型定義ファイルを生成
just clean        # ビルドアーティファクトを削除
just release-check # リリース前チェック（fmt + info + check + test）
```

## プロジェクト構成

```
src/
├── admin/         # 管理画面機能
│   ├── admin_auth.mbt           # 認証ロジック
│   ├── admin_webauthn.mbt       # WebAuthn 実装
│   ├── admin_session.mbt        # セッション管理（JWT）
│   ├── admin_credential_repo.mbt # WebAuthn 認証情報リポジトリ
│   ├── admin_env.mbt            # 環境変数・D1/KV取得
│   ├── admin_form.mbt           # フォーム処理
│   ├── admin_js.mbt             # JS interop
│   ├── admin_repo.mbt           # 記事CRUD操作
│   ├── admin_response.mbt       # HTTPレスポンス生成
│   ├── admin_routes.mbt         # ルーティング
│   ├── admin_templates.mbt      # HTMLテンプレート
│   └── admin_types.mbt          # 型定義
├── config/        # サイト設定（blog.toml から自動生成）
│   └── site_config.mbt
├── handlers/      # パブリック側リクエストハンドラー
│   └── posts.mbt
├── lib/          # ユーティリティ
│   └── markdown.mbt           # Markdown レンダラー
├── models/       # データモデル
│   └── post.mbt
├── repository/   # パブリック側データベースアクセス層
│   └── post_repo.mbt
├── templates/    # TMPX HTML テンプレート
│   ├── layout.mbt             # 共通レイアウト
│   ├── post_detail.mbt        # 記事詳細ページ
│   └── post_list.mbt          # 記事一覧ページ
└── worker/       # Cloudflare Worker エントリーポイント
    ├── main.mbt               # メインハンドラー
    └── router.mbt             # ルーティング

config/
└── blog.toml     # サイト設定（タイトル、フッター文言等）

static/
├── styles.css       # スタイルシート
├── mhx.js           # MHX インタラクティブライブラリ
└── ogp-default.png  # OGP デフォルト画像
```

## アーキテクチャ

### レイヤー構成

1. **Worker Layer** (`src/worker/`)
   - Cloudflare Workers のエントリーポイント
   - JS extern を使用した D1 アクセス（async 制約回避）

2. **Handler Layer** (`src/handlers/`, `src/admin/`)
   - パブリック側：ブログ記事の表示
   - 管理画面：記事の CRUD 操作、WebAuthn 認証

3. **Repository Layer** (`src/repository/`, `src/admin/admin_repo.mbt`)
   - データベースアクセスの抽象化
   - パブリック用と管理用で分離

4. **Model Layer** (`src/models/`)
   - ドメインモデル（`Post`、`PostStatus` など）

5. **Template Layer** (`src/templates/`, `src/admin/admin_templates.mbt`)
   - TMPX による型安全な HTML 生成

6. **Config Layer** (`src/config/`)
   - TOML から生成されるサイト設定

### D1 async 制約への対応

Cloudflare Worker の fetch handler 直下で MoonBit の async API を使うとコルーチン外で `Promise.wait()` が呼ばれ `$panic` になる問題があります。

このため、`src/worker/main.mbt` では **JS extern で D1 を叩く**形にしています。

## 管理画面

### 認証

WebAuthn で保護されています。初回のみセットアップトークンで登録が必要です。

#### 環境設定

`wrangler.toml.example` を `wrangler.toml` にコピーして設定します。

```bash
# wrangler.toml
[[kv_namespaces]]
binding = "ADMIN_AUTH"
id = "YOUR_KV_NAMESPACE_ID"  # wrangler kv:namespace create "ADMIN_AUTH" で取得

[[kv_namespaces]]
binding = "OAUTH_AUTH"
id = "YOUR_OAUTH_KV_NAMESPACE_ID"  # OAuth 用 WebAuthn credential/challenge 専用

[vars]
RP_ID = "your-domain.com"        # WebAuthn Relying Party ID
RP_ORIGIN = "https://your-domain.com"  # オリジン
RP_NAME = "Your Site Name"       # サイト名
OAUTH_RP_ID = "your-domain.com"  # OAuth resource-owner WebAuthn RP ID
OAUTH_RP_ORIGIN = "https://your-domain.com"
```

#### シークレット（本番環境）

```bash
# 1Password で管理することを推奨
ADMIN_USER_ID   # 管理者ユーザーID
JWT_SECRET      # JWT シークレット
ADMIN_SETUP_TOKEN # 初回登録用トークン（使い捨て）
OAUTH_USER_ID   # OAuth resource-owner 用ユーザーID（ADMIN_USER_ID とは別設定）
```

OAuth の WebAuthn credential は `ADMIN_AUTH` へ暗黙にフォールバックしません。
同一 RP の既存 admin passkey を初回 E2E に再利用する場合は、Cloudflare KV 上の
`credentials:${ADMIN_USER_ID}` の値だけを `OAUTH_AUTH` の
`credentials:${OAUTH_USER_ID}` へ明示的に複製してください。`challenge:*` はコピーしません。
OAuth 専用の登録 UI/API は現時点では提供していないため、この複製は deployment bootstrap
として扱います。

```bash
# 値をターミナルへ表示せず、credential レコードだけを複製する例
opz run blog -- sh -c '\
  set -eu; umask 077; tmp=$(mktemp); trap "rm -f $tmp" EXIT; \
  npx wrangler kv key get "credentials:$ADMIN_USER_ID" \
    --binding ADMIN_AUTH --remote --text > "$tmp"; \
  test -s "$tmp"; \
  npx wrangler kv key put "credentials:$OAUTH_USER_ID" \
    --binding OAUTH_AUTH --remote --path "$tmp"\
'
```

#### 初回登録

1. `ADMIN_SETUP_TOKEN` を設定
2. `/admin/register` にアクセス
3. トークンを入力して WebAuthn 登証器を登録
4. 登録完了後、`ADMIN_SETUP_TOKEN` は削除推奨

### 機能

- **記事一覧** (`/admin`): 全記事のリストを表示
- **新規作成** (`/admin/posts/new`): 新しい記事を作成
- **編集** (`/admin/posts/{id}/edit`): 記事を編集
- **プレビュー** (`/admin/preview/{id}`): 記事のプレビュー表示
- **削除** (`POST /admin/posts/{id}/delete`): 記事を削除
- **公開/下書き** (`POST /admin/posts/{id}/publish|unpublish`): ステータス変更

### ステータス管理

- `draft`: 下書き（公開されない）
- `published`: 公開済み

## マイグレーション

### v0.3 スキーマ変更点

- `slide_flag` カラムの追加（0: 通常記事, 1: SVG スライド）

### マイグレーション手順

既存の DB がある場合は admin/content/OAuth の各 migration を適用してください。

```bash
# ローカル
just migrate-db

# 本番
just deploy-migrate-db
```

マイグレーションでは既存データの `slide_flag` が `0` で初期化されます。

## 本番デプロイ時の DB

本番では **schema.sql のみ** を適用し、seed は流さないでください。

```bash
# 本番 DB 初期化
just deploy-db

# マイグレーション（admin/content/OAuth）
just deploy-migrate-db
```

## 記事の管理

### 管理画面から作成・編集（おすすめ）

`/admin` から管理画面にアクセスし、記事の作成・編集が可能です。

### SQL で直接追加

```bash
npx wrangler d1 execute blog-db --local --command \
  "INSERT INTO posts (title, slug, excerpt, content, slide_flag, status, published_at, updated_at)
   VALUES ('My Post', 'my-post', 'short excerpt', 'full content', 0, 'published',
           datetime('now'), datetime('now'));"
```

## MCP サーバー

このブログは MCP (Model Context Protocol) サーバーとして動作し、Devin や
ChatGPT などの MCP クライアントから記事を管理できます。

- エンドポイント: `POST https://blog.f12o.com/mcp`（Streamable HTTP、stateless）
- プロトコル: MCP `2026-07-28`（initialize ハンドシェイクなし）
- メソッド: `server/discover`、`tools/list`、`tools/call`

### 必須ヘッダー

各リクエストで、HTTP ヘッダーがボディと一致している必要があります。

- `MCP-Protocol-Version: 2026-07-28`
- `Mcp-Method`: JSON-RPC の `method` と同じ値
- `Mcp-Name`: `tools/call` のみ必須。`params.name` と同じ値
- `Accept`: `application/json` と `text/event-stream` の両方を含むこと
- `Content-Type: application/json`
- ボディの `params._meta["io.modelcontextprotocol/protocolVersion"]` も `2026-07-28`

### 認証とスコープ

`/mcp` は OAuth 2.1 の保護リソースです。RFC 9728 の protected-resource
metadata と RFC 8414 の authorization-server metadata を公開し、
PKCE (S256) + WebAuthn ベースの同意画面でトークンを発行します。

- すべての `/mcp` リクエスト: `mcp:discover` スコープが必須
- `tools/call` には加えてツールごとのスコープ:
  - `list_posts` / `get_post` → `blog:read`
  - `create_post` / `update_post` → `blog:write`
  - `publish_post` → `blog:publish`
  - （削除ツールはありません）
- スコープ不足は HTTP 403 `insufficient_scope`、未認証は 401 +
  `WWW-Authenticate` チャレンジ
- `offline_access` で refresh token ローテーションも発行可能

### クライアント登録

OAuth クライアントは2つの経路で解決されます。

- **CIMD (Client ID Metadata Document)**: `client_id` が HTTPS の
  メタデータ文書 URL の場合、その文書を取得して検証します（推奨経路）。
- **DCR (RFC 7591)**: `POST https://blog.f12o.com/oauth/register` で動的
  クライアント登録が可能です。ChatGPT のように事前登録された
  `client_id`/`client_secret` を必要とするクライアント向けです。
  authorization-server metadata の `registration_endpoint` で広告されるため、
  対応クライアントは自動で登録します。`token_endpoint_auth_method` が
  `none` 以外のクライアントには `client_secret` を一度だけ発行し、
  サーバーには SHA-256 ハッシュのみ保存します。

### ツール

`list_posts`, `get_post`, `create_post`, `update_post`, `publish_post` の5つ。
引数は JSON Schema 2020-12 で厳密に検証され、スキーマ違反は JSON-RPC
`-32602` (HTTP 400)。実行時の失敗（記事が無い、バリデーション、DB エラー）は
HTTP 200 の CallToolResult `isError: true` で返ります。

### クライアントからの接続

- **Devin (app.devin.ai)**: Organization Settings からカスタム MCP サーバー
  として `https://blog.f12o.com/mcp` を追加。HTTP トランスポート・OAuth で
  接続すると同意画面が開き、必要スコープを承認して利用します。
- **ChatGPT (chatgpt.com)**: コネクタ（MCP 対応）として同じ URL を指定します。
  OAuth フロー経由でトークンを取得後、`tools/call` が使えます。

クライアント側の UI 名称や設定手順は各プロダクトのドキュメントを参照して
ください。

詳細なプロトコル仕様とエラー契約は
[docs/mcp-protocol-architecture.md](docs/mcp-protocol-architecture.md) と
[docs/oauth-mcp-architecture.md](docs/oauth-mcp-architecture.md) を参照。

## サイト設定

ブログのタイトルやフッター文言は `config/blog.toml` で管理します。
変更後は `just gen-config` または `just build` を実行してください。

```toml
site_title = "My Blog"
site_description = "A simple blog"
footer_html = "&copy; 2024 My Blog"
```

注意: 現在の TOML パーサはフラットな `key = "value"` のみ対応しています。

## MHX の読み込み

`static/mhx.js` を配信しているので、HTML では次のように読み込まれます。

```html
<script src="/mhx.js" defer></script>
```

## ページネーション

記事一覧ページではページネーションが利用可能です。

- デフォルト: 10件/ページ
- 最大: 50件/ページ
- クエリパラメータ `?page=N` でページ指定

## RSS Feed

RSS フィードは `/rss.xml` で配信されます。

- Content-Type: `application/rss+xml; charset=utf-8`
- 公開済み記事の最新30件を含みます

## Markdown 記法

### Raw Markdown 配信

記事URLの末尾に `.md` をつけると、raw markdown を返します。

- 例: `/posts/hello-world.md`
- Content-Type: `text/markdown; charset=utf-8`
- 先頭に [OKF (Open Knowledge Format) v0.1](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) 準拠の YAML front matter が付きます:
  - `type`（`Slide Deck` または `Blog Post`）
  - `title`
  - `description`（記事の excerpt）
  - `resource`（記事の絶対 URL）
  - `timestamp`（最終更新日時）
- publication date は OKF に標準キーが無いため、本文先頭に `*Published: ...*` の行として畳み込まれます。

### 本文で使える記法

- 画像: `![alt text](https://example.com/image.png)` / `![alt text](/static/image.png)`
- 埋め込み: `[!embed](URL)`
  - YouTube URL
  - Google Slides（`docs.google.com/presentation/d/.../embed`）
  - SpeakerDeck（`speakerdeck.com/player/...`）
  - SlideShare（`slideshare.net/slideshow/embed_code/...`）

注: SpeakerDeck / SlideShare は埋め込みURL前提です。通常の共有URLはリンクカード表示にフォールバックします。

## OGP/Twitter Card 対応

各記事ページで OGP と Twitter Card のメタタグを出力します。

- デフォルト画像: `static/ogp-default.png`
- 記事ごとのタイトル、説明、画像の設定が可能
- SNS での共有時に最適化されたプレビューが表示されます

## 技術スタック

- **MoonBit**: メインの実装言語
- **Cloudflare Workers**: サーバーレス実行環境
- **D1**: エッジ SQLite データベース
- **KV**: WebAuthn 認証情報・チャレンジ保存
- **TMPX**: 型安全な HTML テンプレートエンジン
- **MHX**: ハイパーメディア駆動のインタラクティブ機能
- **WebAuthn**: 生体認証・セキュリティキーによるログイン
- **OGP/Twitter Card**: SNS 共享対応

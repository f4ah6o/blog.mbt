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
just migrate-db   # ローカル DB を v0.2 スキーマにマイグレーション
just seed-db      # シードデータを投入
```

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

[env.production.vars]
RP_ID = "your-domain.com"        # WebAuthn Relying Party ID
RP_ORIGIN = "https://your-domain.com"  # オリジン
RP_NAME = "Your Site Name"       # サイト名
```

#### シークレット（本番環境）

```bash
# 1Password で管理することを推奨
ADMIN_USER_ID   # 管理者ユーザーID
JWT_SECRET      # JWT シークレット
ADMIN_SETUP_TOKEN # 初回登録用トークン（使い捨て）
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

### v0.2 スキーマ変更点

- `status` カラムの追加（draft/published）
- `published_at` を NULL 可能に変更
- `updated_at` の適切な運用

### マイグレーション手順

既存の DB がある場合は `migrate_admin_v02.sql` を適用してください。

```bash
# ローカル
just migrate-db

# 本番
just deploy-migrate-db
```

マイグレーションでは既存データは以下のように変換されます：
- `published_at` に値があった場合 → `status: published`
- `published_at` が空の場合 → `status: draft`
- `updated_at` が空の場合 → 現在時刻をセット

## 本番デプロイ時の DB

本番では **schema.sql のみ** を適用し、seed は流さないでください。

```bash
# 本番 DB 初期化
just deploy-db

# マイグレーション（v0.2 以降）
just deploy-migrate-db
```

## 記事の管理

### 管理画面から作成・編集（おすすめ）

`/admin` から管理画面にアクセスし、記事の作成・編集が可能です。

### SQL で直接追加

```bash
npx wrangler d1 execute blog-db --local --command \
  "INSERT INTO posts (title, slug, excerpt, content, status, published_at, updated_at)
   VALUES ('My Post', 'my-post', 'short excerpt', 'full content', 'published',
           datetime('now'), datetime('now'));"
```

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

## Markdown 記法

### Raw Markdown 配信

記事URLの末尾に `.md` をつけると、raw markdown を返します。

- 例: `/posts/hello-world.md`
- Content-Type: `text/markdown; charset=utf-8`
- 先頭に YAML front matter が付きます:
  - `title`
  - `slug`
  - `excerpt`
  - `published_at`
  - `updated_at`
  - `url`

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

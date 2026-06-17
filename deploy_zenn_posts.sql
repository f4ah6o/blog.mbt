-- Publish selected Zenn articles to the production D1 database.
-- Safe to run repeatedly: only these three slugs are inserted or updated.
INSERT INTO posts (
  title,
  slug,
  excerpt,
  content,
  slide_flag,
  status,
  published_at,
  updated_at
)
VALUES
  (
    '既存のWebアプリに注釈UIを足すViteプラグイン「Markable」を作った',
    'markable-vite-plugin',
    'Webアプリに注釈とコメント機能を追加するViteプラグイン Markable を作りました。',
    '## 成果物

Webアプリに注釈とコメントの機能を追加するViteプラグインを作りました。
既存の画面にレイヤーを重ね、右下のボタンから対象要素や画面範囲を選んでコメントできます。

[!embed](https://github.com/f4ah6o/markable)

動くサンプルはこちらです。
別の方が作ったWebアプリのサンプルにMarkableを追加しています。

https://f4ah6o.github.io/markable/

Vue Todoデモでは、既存の画面へ注釈UIを重ねています。

![Vue TodoデモにMarkableの注釈UIを重ねた画面](/images/markable-vite-plugin/vue-todo-markable.png)

[オリジナルのサンプルページ](https://hefengxian.github.io/vue3-ts-vite-vitest-todo/)と並べると、アプリ本体はそのままで、右下にfeedbackボタンだけが追加されていることがわかります。

![オリジナルのVue TodoデモとMarkableを追加したVue Todoデモの比較](/images/markable-vite-plugin/vue-todo-original-vs-markable.png)

本番向けのfeedbackモードでは、右下にフィードバックを想定したボタンを表示します。

![Vue Todoデモにfeedbackボタンを表示した画面](/images/markable-vite-plugin/feedback-button.png)

コメント対象は、DOM要素として選ぶことも、画面上の矩形範囲として選ぶこともできます。

![要素選択とBox選択をしている Markable の画面](/images/markable-vite-plugin/element-and-box-selection.png)

登録後は、最近のマークとして画面上に残ります。
JSONボタンから、対象要素やビューポートなどを含むデータをコピーできます。

![Markableで登録したコメントが最近のマークとして表示された画面](/images/markable-vite-plugin/after-save.png)

## きっかけ

Codex appのIn-appブラウザにある注釈機能が便利だと思っていたところ、次のポストを見つけました。

[!embed](https://x.com/u1/status/2065832522198761650)

リポジトリはこちらです。
MITライセンスで公開されています。

[!embed](https://github.com/u-ichi/reviewable-html-workbench)

注釈UI/UXはエージェントと人間のやり取りだけでなく、人間同士の不具合報告、フィードバックにも使えそうだと感じました。

## Viteプラグインにした理由

欲しかったのは、アプリの本体とは別に差し込める注釈レイヤーです。

開発中のレビューでも、運用中のフィードバックでも、必要な操作はあまり変わりません。
起動するボタンがあり、画面上の要素や範囲を選び、コメントを入力できればよいはずです。

そのため、できるだけ既存の実装を触らずに追加できる形にしたくなりました。
最初に思いついたのがViteプラグインです。
Viteのアプリであれば、プラグインを設定するだけで同じ注釈UIを追加できます。

## 設定方法

使う側で必要なのは、パッケージのインストールと `vite.config.ts` への追加です。

```bash
pnpm add @f12o/markable
```

Viteの設定では、通常のプラグインと同じように`plugins`へ追加します。

```ts
import { defineConfig } from "vite";
import { markable } from "@f12o/markable/vite";

export default defineConfig({
  plugins: [
    markable({
      mode: "auto",
      locale: "ja",
      commentsFile: ".markable/comments.json",
      endpoint: "/__markable/comments",
      poweredBy: true,
    }),
  ],
});
```

`mode: "auto"`にすると、Viteの開発時はreviewモード、本番ビルド時はfeedbackモードになります。
開発中はレビュー用の「Mark」ボタンを出し、本番では利用者向けの「Feedback」ボタンを出す想定です。

`commentsFile`は、開発サーバーで投稿された注釈を保存する JSONファイルです。
`endpoint` は、そのJSONを読み書きするためのローカルエンドポイントです。
静的な GitHub PagesではPOST先がないため、外部の保存先を設定しない限り、投稿内容はそのセッション内の表示に留まります。

`locale` には `"en"` と `"ja"` を指定できます。
ボタン、入力欄、保存後の表示など、Markable が注入する UI の文言が切り替わります。

アプリ本体のコンポーネントは変更しません。
Vite プラグインがHTMLにMarkableのクライアントスクリプトを注入します。

## 実装まで

初期実装はCodexもClaude Codeも使わず、チャットで進めました。
Vite プラグインとして実装できそうだとわかり、そのまま GitHub プラグインからリポジトリを操作し、コードまで書いてもらいました。

リポジトリの作成と GitHub Pages の設定は、iPhone のブラウザから行いました。
パソコンを開かなくても、GitHub Pages にデプロイしたサンプルページまで確認できました。

今後は、
- 登録済みの注釈位置にピンを表示
- エージェントと共有する動線の確立
などを追加できればと思います。
',
    0,
    'published',
    '2026-06-17T10:28:41Z',
    '2026-06-17T12:44:44Z'
  ),
  (
    '1password-cli`op`のCLIラッパー`opz`を作った',
    'opz-is-1password-cli-wrapper',
    '1Password CLI の op を使いやすくする CLI ラッパー opz を作りました。',
    '1Password CLIの`op`コマンドを使うと、1Passwordに保存しているシークレットを環境変数としてそのまま利用できます。
パスワードやAPIトークンを平文で保存せず、セキュリティ的に安心です。

ですが、実際に使ってみて不便さを感じ、CLIラッパーの`opz`を作りました。

[!embed](https://github.com/f4ah6o/opz)

## `op run`のつらさ

1. 毎回`.env`を作成するのが面倒
2. 環境変数名を覚えられない
3. `op://<vault>/<item>/<field>`という参照パスが長くて覚えられない。特に日本語で項目名を保存するとIDが含まれるので、毎回コピペが必要
4. `op run --env-file <item-name> -- <command>`コマンドが長い

## `opz`のゴール

### 1. 無駄なくコマンドを実行したい

```bash
opz <item-name> -- <command>
```

### 2. `.env`の生成

```bash
opz gen <item-name> [.env]
```

### 名前について
`opx`にしたかったのですが、[既に存在](https://crates.io/crates/opx)していました。

## 覚えること/覚えられること

* `<item-name>`: 1Passwordに登録した項目名
* `<command>`: 実行したいコマンド

## 1Passwordでの設定

コマンド実行に必要な環境変数はすべてitemに保存しておきます。

1. 各フィールドのラベルに環境変数名を入力する（例: `API_KEY`）
2. シークレット以外の情報も登録する（例: APIのURLなど）
3. アイテム名は覚えやすいものにする（日本語OK）

## 使い方

### 前提

* `op`を設定済み
* `cargo`

### インストール

```bash
cargo install opz
```

### 基本形

```bash
# 項目名を指定してコマンドを実行
opz <item-name> -- <command>
# opz run <item-name> -- <command>  # 同じ意味
```

### サブコマンド

```bash
# 項目をキーワード検索
opz find <keyword>

# .envファイルのみ生成
opz gen <item-name> [env file name]
```

## 動作フロー

コマンド実行時の内部処理は以下の通りです。

1. `op item list`で項目一覧を取得し、指定した項目名を検索
2. `op item get`で項目のフィールド情報を取得し、`op://`形式で参照文字列を構築
3. 環境変数をインラインで直接代入する時に`op read`を使用してコマンドを実行
  * 本当は`op run --env-file`を使いたかったが、Claudeで起動に失敗するため断念
',
    0,
    'published',
    '2025-12-25T03:56:45Z',
    '2026-06-17T12:49:10Z'
  ),
  (
    'Badgeをシュッとつくれるcliつくった',
    'bdg-generate-badges-quickly',
    'README によくある Badge を簡単に作れる CLI bdg を作りました。',
    'READMEによくあるBadgeを簡単につくれるcli`bdg`をつくりました。
<!-- bdg:begin -->
[![crates.io](https://img.shields.io/crates/v/bdg.svg)](https://crates.io/crates/bdg)
[![CI](https://github.com/f4ah6o/bdg-rs/actions/workflows/rust.yaml/badge.svg)](https://github.com/f4ah6o/bdg-rs/actions/workflows/rust.yaml)
<!-- bdg:end -->
こういうのをたまに作りたくなるのですが、検索性が悪い上に作り方もよくわからない！ということである程度覚えやすく、自動化できるようになりました。

## 成果物

[!embed](https://github.com/f4ah6o/bdg-rs)

## 機能

自分がよく使うパッケージレジストリ等に対応させています。
- JavaScript(Node), Rust, Moonbitを認識
- ライセンス、GitHub Actionsも認識
- README.mdにShields.ioの形式のリンクを自動挿入

## 使い方

インストールは`cargo`をつかいます。
```bash
cargo install bdg
```

### 実行
```bash
bdg add
```

コマンドは覚えられないのでTUIでインタラクティブに実行します。

### 削除

```bash
bdg remove
```
',
    0,
    'published',
    '2026-01-29T13:06:12Z',
    '2026-06-17T12:49:10Z'
  )
ON CONFLICT(slug) DO UPDATE SET
  title = excluded.title,
  excerpt = excluded.excerpt,
  content = excluded.content,
  slide_flag = excluded.slide_flag,
  status = excluded.status,
  published_at = excluded.published_at,
  updated_at = excluded.updated_at;

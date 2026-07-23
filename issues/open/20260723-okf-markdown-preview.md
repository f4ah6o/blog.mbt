# OKF Markdownを正本にしたローカルPreviewとD1投影を導入する

Status: open
Model: unknown
Created: 2026-07-23
Updated: 2026-07-23
Branch: codex/feat/20260723-okf-markdown-preview

## 概要

Private Gitリポジトリで管理するOKF/LLM Wiki形式のMarkdownを記事の正本とし、既存のD1 `posts` テーブルへ投影して、本番と同じブログ画面をローカルでPreviewできるようにする。

## 背景

- 現在のブログはMoonBit + Cloudflare Workers + D1で構成され、`just local` はビルド、ローカルD1初期化・シード、開発サーバー起動を行う。
- 現在の記事本文はD1 `posts` テーブルに保存され、管理画面がD1を直接読み書きしている。
- LLM Wiki/Open Knowledge Format（OKF）は、Markdown、YAML frontmatter、`index.md`、`log.md`、標準Markdownリンクを中心に知識を管理する形式である。
- 現在のWorkerは `/posts/:slug.md` でOKF v0.1互換のMarkdownを返し、サイト記事のtypeとして `Blog Post` と `Slide Deck` を使用している。
- 正本となるOKF bundleは、公開されている `blog.mbt` リポジトリとは分離したPrivate Gitリポジトリで管理する。
- OKFの概要: https://okf.md/faq/
- 将来は、公開記事だけをCloudflare上のD1/R2へ同期し、`private → public` の公開操作を明示的なPublisher経路に限定する。これは本イシューでは実装しない。

## 問題

- D1が記事の正本になっているため、LLM・エディタ・Gitで扱えるMarkdown知識基盤を構築できない。
- Markdownを編集しても、現在のローカルPreviewへ自動反映する経路がない。
- 既存記事をMarkdownへ移行する場合のfrontmatter、公開状態、slug、記事本文とD1の対応が定義されていない。
- Private知識と公開記事を同じ形式で管理する場合に、記事以外の知識をD1へ誤って投影するリスクがある。

## 目標

- Private OKF bundleを入力として、記事だけをD1 `posts` へ投影できる。
- ローカルPreviewを起動して、現行のブログレイアウト、Markdownレンダリング、リンクカード、スライド表示を確認できる。
- OKF Markdownの保存を検知するとローカルD1へ自動同期され、Previewへ反映される。
- 既存D1記事をOKF Markdownへ一括移行でき、slug、タイトル、本文、公開状態、公開日時を保持できる。
- `concept`、`decision`、`architecture`、`runbook` などの記事以外の知識はD1 `posts` へ同期されない。
- 本番の公開経路やCloudflare上のPrivate知識取り扱いに必要な後続作業を妨げないインターフェースを定義する。

## 対象外

- R2バケットの作成、Rcloneの `nfsmount`、macOS Finder連携。
- 記事画像・動画のR2移行、`media.<domain>` の公開ドメイン設定。
- Private Gitリポジトリの作成・GitHub Appの設定・GitHub webhook。
- Cloudflare Publisher Worker、Queues、Access、D1本番同期。
- `private → public` の高リスク公開承認フローと `just promote`。
- 本番管理画面の削除。公開経路の切り替え時に後続Issueで扱う。

## 提案する方針

### OKF bundleの入力構造

Privateリポジトリ側を次の構造にする。

```text
knowledge/
  index.md
  log.md
  articles/
    <slug>.md
  concepts/
  decisions/
  architecture/
  runbooks/
```

記事Markdownは少なくとも次のfrontmatterを持つ。`visibility` が欠落または不正な記事は、同期対象から除外してエラーにする。

```yaml
---
type: Blog Post
status: draft
visibility: private
title: Example title
slug: example
excerpt: Example excerpt
published_at: null
---
```

サイト記事の投影対象は `type: Blog Post` と `type: Slide Deck` とし、既存のraw Markdown出力との互換性を保つ。その他のtypeはLLM Wiki知識として扱う。`status` は `draft`、`published`、`archived` を受け付ける。`visibility` は `private` または `public` とする。frontmatter以外の本文は既存のMarkdownレンダラーへ渡す。

### D1投影

- 既存の `posts` スキーマを初期投影先として利用する。
- slugを論理キーにして冪等にupsertし、既存slugのD1 `id` は可能な限り保持する。
- `type` が `Blog Post` または `Slide Deck` でないファイルは投影しない。
- ローカルPreviewでは `draft`、`published`、`archived` をローカルD1へ同期する。
- 公開側の既存ハンドラーは `published` の記事だけを返す。draftの確認にはローカル専用Preview経路を用意し、本番公開経路からは利用できないようにする。
- `visibility` は同期判定に使用し、将来の本番Publisherが `visibility: public` の記事だけを公開できるよう、投影処理の境界を分離する。

### ローカルPreview

- `just local` の既存用途を壊さず、OKF bundleを入力にする `just preview` または同等のコマンドを追加する。
- Preview起動時にMarkdownをD1へ投影し、その後はファイル変更を監視して差分を自動同期する。
- Previewは現行のWorker/Vite開発サーバーを利用し、別実装のMarkdown表示サーバーを作らない。
- draftを確認できるローカル専用経路を用意する。経路は本番ビルドで無効化または認証なしでは利用できない形にする。
- Private bundleの場所は環境変数またはローカル設定から指定し、公開リポジトリへ知識本文をコピーすることを必須にしない。

### 既存記事の移行

- D1から既存 `posts` を読み出し、1記事1Markdownへ変換する移行ツールを用意する。
- slugをファイル名とし、タイトル、excerpt、本文、status、published_at、`slide_flag`相当のtype情報をfrontmatterへ移す。
- 既存の公開記事は初期移行時に公開済み記事として識別できる情報を残す。ただし、本番公開への反映は後続のPublisher設計で明示的に扱う。
- 移行結果を再投影して、主要フィールドのラウンドトリップ差分を検査できるようにする。
- 既存D1を直ちに破棄せず、移行結果の検証完了後に正本をMarkdownへ切り替える。

### コマンドと検証

- frontmatter、slug重複、予約語、Markdownリンク、記事種別を検証するコマンドを追加する。
- Agentと人間が同じコマンドを使えるよう、検証・Preview・同期の結果は機械可読な終了コードと要約を返す。
- 高リスク公開用の `promote` は本イシューでは実装せず、通常同期が公開状態を勝手に変更しない境界だけをテストする。

## 受け入れ条件

- [ ] Private OKF bundleの`index.md`、`log.md`、`articles/`を入力として読み込める。
- [ ] `type: Blog Post` または `type: Slide Deck` のMarkdownだけがD1 `posts`へ投影され、その他のOKF知識は投影されない。
- [ ] `status: draft|published|archived` と `visibility: private|public` のfrontmatterを検証できる。
- [ ] slugをキーにした再実行可能なD1 upsertが実装され、既存slugの基本データが重複しない。
- [ ] `just preview` または同等のコマンドで、現行ブログのローカルPreviewを起動できる。
- [ ] Markdown保存後にローカルD1が自動更新され、Previewで変更を確認できる。
- [ ] ローカルPreviewでdraft記事を確認でき、通常の公開ルートからdraft記事が返らない。
- [ ] D1から既存記事をMarkdownへ移行できる。
- [ ] 移行前後でslug、title、content、status、published_atの差分を検査できる。
- [ ] Private OKF bundleの実体を公開Gitリポジトリへ追加せずにローカルPreviewを実行できる。
- [ ] 不正なfrontmatter、slug重複、未知のstatus/type/visibilityを検出して非ゼロ終了する。
- [ ] `just check`、`just test`、既存の`just local`の動作を壊さない。

## テスト計画

- `moon check --deny-warn --target js`
- `moon test --target js`
- `pnpm exec vp check src/worker-entry.ts src/client/markable.ts src/types.d.ts vite.config.ts vite.markable.config.ts package.json tsconfig.json`
- OKF fixtureを使ったfrontmatter・種別・公開状態・slug重複の単体テスト。
- ローカルD1へ投影し、公開記事・draft記事・非記事知識をそれぞれ確認する統合テスト。
- Markdownを変更してPreviewが自動同期される手動確認。
- 移行ツールのラウンドトリップ差分確認。
- `just local` の既存フローを起動して回帰確認する。

## リスク

- Private bundleを読み込むローカルパス、frontmatterの完全なOKF仕様、既存記事のexcerptやslide metadataの対応は実装時に確定する必要がある。
- D1を先に正本扱いから外すと、移行失敗時に記事編集が失われるため、移行ツールは読み取り・出力・差分検査を分離する。
- slug変更はD1の論理キー変更になるため、本イシューでは自動renameを行わず、衝突をエラーにする。
- draftのローカルPreview経路が本番へ混入すると非公開記事が漏洩するため、ビルド時・ルーティング時の無効化を検証する。
- `visibility: public` の記事を本番へ公開する処理は別の高リスク経路で扱い、通常のローカル同期では公開副作用を発生させない。
- 既存記事の移行時にHTML化済み本文や外部画像URLの意味が変わらないことを確認する。

## 変更履歴

`CHANGES.md` impact: yes

項目案：

- OKF Markdownを記事の正本として扱うローカルPreview・D1投影ワークフローを追加する。

## 注記

- 現行リポジトリは公開コードリポジトリであり、Private知識本文は別リポジトリに置く。
- R2/Finder、Publisher Worker、Queue、Access、`promote` は後続段階で追加する。
- CloudflareのWorkers BuildsはPrivate GitHubリポジトリをGitHub Appで接続できるが、今回の段階ではPublisherの実装方法を固定しない。

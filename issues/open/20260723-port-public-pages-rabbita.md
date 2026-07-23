# 公開ページをRabbitaへ移行する

Status: open
Model: unknown
Created: 2026-07-23
Updated: 2026-07-23
Branch: feature/port-to-rabbita

## 概要

基準コミット `5d185c9` から、公開ページのHTMLビューと記事一覧のページングをRabbitaへ移行する。SSR・SEO・既存の公開URLとデザインを維持し、Markableは継続利用する。

## 背景

- 基準コミット: [5d185c9](https://github.com/f4ah6o/blog.mbt/commit/5d185c9)
- 現在の公開ページはMoonBitのTMPXビューでSSRされ、記事一覧のページングはMHXによる部分HTML置換を使用している。
- Rabbitaは公開版 `0.13.1` を使用する。[moonbit-community/rabbita](https://github.com/moonbit-community/rabbita)
- Proped-Rabbitaは最新の `main` を追従し、記事一覧の状態・遷移検証に使用する。[f4ah6o/Proped-Rabbita](https://github.com/f4ah6o/Proped-Rabbita)
- MarkableのVite統合と生成クライアントは継続利用する。[f4ah6o/markable](https://github.com/f4ah6o/markable)
- 記事管理の正本・投影方法は本イシューの対象外とし、公開側は既存の `BlogPost` 読み取り境界を利用する。

## 問題

- 公開ページのビューがTMPXに依存しており、Rabbitaの型付きモデル・更新・ビュー構成を利用できていない。
- ページングの状態遷移がMHXと部分HTMLレスポンスに分散しており、Proped-Rabbitaで検証できない。
- SSRの初期表示とクライアント側のページング状態を共有する明確なモデル境界がない。

## 目標

- `/`、`/posts`、`/posts/:slug`、公開404・エラーページのビューをRabbitaへ移行する。
- SSRとSEOを維持し、SSRで生成した初期記事一覧をRabbitaクライアントへ渡す。
- 記事一覧のページングをMHXからRabbitaへ完全移行する。
- ページングAPIをJSON化し、SSR初期モデルと同じ公開DTOスキーマを使用する。
- JavaScriptが無効またはクライアントバンドルが失敗した場合も、通常リンクによるページ遷移を利用可能にする。
- Proped-Rabbitaで記事一覧の到達可能な状態と遷移を検証し、リリースチェックへ組み込む。
- 既存の表示、文言、URL、HTMLセマンティクス、メタタグ、Markableの配置を維持する。

## 対象外

- 管理画面のRabbita移行、または管理画面の廃棄。
- Papyr本体のRabbita対応。
- 記事管理の正本、OKF bundle、D1投影処理、D1スキーマの変更。
- RSS (`/rss.xml`)、raw Markdown (`/posts/:slug.md`)、OGP API (`/api/ogp`) の形式変更。
- スライドデッキの専用SVGレンダラーのRabbita移行。
- Markableの置き換え、設定変更、コメントデータ形式の変更。
- 公開ページのデザイン刷新。

## 提案する方針

1. `5d185c9` を基準に、Rabbita `0.13.1` をMoonBit依存へ追加する。Proped-Rabbitaは最新 `main` を依存させる。
2. 公開ページ用のRabbitaモデル・メッセージ・更新・ビューを独立したMoonBitパッケージとして追加する。公開ページの旧TMPXビューは移行後に削除し、管理画面のコードは変更しない。
3. PapyrのMarkdown解析は変更せず、ブログ側にTMPXノードからRabbitaのHTMLへ変換する出力アダプターを追加する。これによりMarkdown・リンクカード・埋め込みの既存仕様を維持する。
4. 公開HTMLはRabbitaでSSRし、一覧ページでは初期モデルをJSONとして埋め込む。初期モデルと `/api/posts` のレスポンスは次の共通形式とする。

   ```json
   {
     "page": 1,
     "limit": 10,
     "total_pages": 3,
     "posts": [
       {
         "slug": "example",
         "title": "Example",
         "excerpt": "...",
         "published_at": "..."
       }
     ]
   }
   ```

   一覧DTOにはD1内部IDと本文全体を含めない。
5. 既存の `/api/posts` を部分HTMLではなくJSONレスポンスへ変更する。APIエラーはHTTPエラーと機械可読なエラー本文を返す。
6. 一覧ページだけにRabbitaクライアントバンドルを読み込ませる。Rabbitaは初期SSRモデルから開始し、ページ変更時にAPIを取得して状態を更新する。
7. ページング操作では `/posts?page=N&limit=M` のURL形式を維持する。Rabbitaは `history.pushState` と `popstate` を使用し、通常の `<a href>` をJavaScript無効時のフォールバックとして残す。
8. 一覧状態は少なくとも `Loading`、`Ready`、`Error` を持つ。API失敗時は現在の一覧を保持したままエラーと再試行手段を表示する。
9. 公開ページからMHXのページング属性・部分HTML経路・公開レイアウトによるMHX読み込みを除去する。Markableの生成スクリプト、Vite統合、Workerからの配信は維持する。
10. Proped-Rabbitaで、初期SSR、空一覧、通常表示、読み込み中、APIエラー、先頭・中間・末尾ページ、戻る・進む操作を検証する。HTML・JSON・Graphvizの状態アトラスはコミットせずCI成果物として保存する。

## 受け入れ条件

- [ ] `5d185c9` を基準にRabbita公開版 `0.13.1` を使用している。
- [ ] Proped-Rabbitaは最新 `main` を使用し、指定した状態機械の検証を実行できる。
- [ ] `/`、`/posts`、`/posts/:slug`、公開404・エラーページがRabbitaのSSRビューで生成される。
- [ ] SSRのタイトル、canonical/OGP等のメタタグ、既存CSSクラス、記事本文の表示が維持される。
- [ ] Papyr本体を変更せず、ブログ側の出力アダプターでMarkdown・リンクカード・埋め込みをRabbitaビューへ接続できる。
- [ ] 公開ページの旧TMPXビューが削除され、公開HTMLの表示経路がRabbitaへ一本化される。
- [ ] `/api/posts` がページ情報と公開記事DTOをJSONで返し、D1内部IDと本文全体を返さない。
- [ ] SSR初期モデルと `/api/posts` が同じJSONスキーマを使用する。
- [ ] 記事一覧のページングがMHXの部分HTML置換なしにRabbitaで動作する。
- [ ] ページングで `?page=N&limit=M`、`pushState`、`popstate`、通常リンクのフォールバックが維持される。
- [ ] APIの読み込み中・成功・空一覧・失敗・再試行をRabbitaの型付き状態として扱える。
- [ ] Rabbitaクライアントバンドルは一覧ページだけで読み込まれ、Markableは既存の公開ページで継続動作する。
- [ ] Proped-Rabbitaの状態検証が `just release-check` から実行される。
- [ ] 状態アトラスの生成物がGit管理対象に追加されず、CI成果物として確認できる。
- [ ] 管理画面、RSS、raw Markdown、OGP API、スライドデッキの既存動作を変更しない。

## テスト計画

- `moon fmt`
- `moon info`
- `moon check --deny-warn --target js`
- `moon test --target js`
- Proped-Rabbitaの状態・遷移テストを対象とした `moon test --target native` または同等の専用コマンド
- `pnpm exec vp check` に新しいMoonBitクライアント入口、Worker入口、Vite設定を含めて実行
- `just release-check` を実行し、Proped-Rabbitaの検証と既存テストが完了することを確認
- ローカルPreviewで、初期SSR、一覧ページング、戻る・進む、APIエラー、JavaScript無効時のリンク遷移を確認
- `/posts/:slug` でMarkdown、リンクカード、埋め込み、Markableオーバーレイを確認
- `/rss.xml`、`/posts/:slug.md`、管理画面の既存動作を回帰確認

## リスク

- Proped-Rabbitaが最新 `main` 追従でAPIや依存関係を変更すると、ビルドまたはCIが不安定になる可能性がある。
- RabbitaのSSR出力とクライアントmountの間で二重描画や表示のちらつきが発生する可能性があるため、SSR初期モデルの再利用を検証する必要がある。
- `/api/posts` の部分HTML利用者がリポジトリ外に存在する場合、JSON化が互換性に影響する。
- TMPXはブログ側のMarkdown出力アダプターと現行管理画面に暫定的に残る。Papyr対応と管理画面廃棄は後続作業で扱う。
- 既存のMarkdown出力、リンクカード、埋め込みがRabbitaのHTML型へ変換される際に、エスケープや属性の意味が変わらないことを確認する必要がある。
- MarkableのVite注入とRabbitaの公開クライアントバンドルが同じHTMLへ組み込まれるため、script順序、キャッシュ、Worker配信経路を回帰確認する必要がある。

## 変更履歴

`CHANGES.md` impact: yes

項目案：

- 公開ページのRabbita SSRビューとRabbitaベースのクライアントページングを追加し、既存のMHXページングを置き換える。

## 注記

- 2026-07-23: 管理画面は今回の移行対象から除外し、将来廃棄する方針を確認した。
- 2026-07-23: Rabbitaは公開版を使用し、Proped-Rabbitaは最新 `main` を追従する方針を確認した。
- 2026-07-23: Papyr本体は変更せず、ブログ側のTMPX→Rabbita出力アダプターを暫定利用する方針を確認した。

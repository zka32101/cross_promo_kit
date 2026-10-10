# 全アプリ展開の方針（2026-10-05 決定）

## 決定事項

1. **対象は Google Play 公開済みのアプリのみ。** 審査中・非公開のアプリは、公開後に Remote Config のリストへ追加する（コード側の導入は先行してよい）。
2. **紹介は同じシリーズ内だけ。** `category` が一致するアプリ同士で紹介する。
   - `小学コレ` … 算数 / 国語 / 社会 / 理科 / 英語 / プログラミング / 心身 など。小学生向けの「ゲームで学ぶ都道府県」も、小学コレと同じ `小学コレ` カテゴリとして相互に紹介する（2026-10-09 決定）。
   - `うかラボ` … 資格系
   - `パズル・ゲーム` … Card Rivals など
   - 子ども向け（小学コレ）のアプリに、大人向け・別ジャンルのアプリは出さない。
3. **アプリごとに PR を作る。** 導入は pubspec / init / 設定画面の3点。マージ前に実機で表示を確認する。
4. **Remote Config への投入は確認してから。** 本番設定の更新なので、内容（掲載アプリ・URL）を確認してから行う。

## Remote Config は Firebase プロジェクト単位

`cross_promo_apps` はプロジェクトごとに別管理。

| プロジェクト | 使うアプリ |
|---|---|
| `kore1-6b58e` | 算数 / 国語 / 社会 など小学コレ系（共有） |
| アプリ個別のプロジェクト | Card Rivals など。**同じリストを各プロジェクトに投入する必要がある** |

リストを手で同期し続けると漏れる。掲載リストの正は1箇所（このリポジトリの `docs/` か shared_core）に置き、投入作業は同じ手順で行う。

## 導入手順（アプリ側）

1. `pubspec.yaml` に `cross_promo_kit` を **タグ固定**で追加（README 参照。`ref: main` は使わない）
2. `main.dart` の Firebase 初期化の後に `await CrossPromoService.init();`（別の try/catch。失敗しても起動を止めない）
3. 設定画面に `CrossPromoSection(currentAppId: '<applicationId>', currentCategory: '<category>')` を追加
4. **子ども向けアプリは `beforeOpenStore`（保護者ゲート）を必ず渡す**
5. `currentAppId` は **本番の applicationId** と完全一致させる（仮の値だと自分が自分のリストに出る）
6. 実機で、紹介カードの表示と自アプリの除外、タップでストアが開くことを確認する

## 掲載リストの管理と投入手順

掲載リストの正は **`docs/cross_promo_apps.json`**（このリポジトリ）。Remote Config の値は必ずここから作る。
プロジェクトごとの Remote Config（`kore1-6b58e` / アプリ個別のプロジェクト）には、同じ内容を投入する。

1. `docs/cross_promo_apps.json` を編集する（公開を確認したアプリだけ）。
2. 検証する: `python3 tools/cross_promo_list.py validate --check-urls`
   - 必須項目、`id` の重複、デバッグサフィックス、Play の URL と `id` の一致、カテゴリの綴り、
     `storeUrl` / `iconUrl` が HTTP 200 を返すかを確認する。
3. 投入用の値を出す: `python3 tools/cross_promo_list.py snippet`
4. **掲載アプリ・URL を確認してから**、各プロジェクトの Remote Config に同じ値を設定して公開する（方針の4）。
   Firebase CLI で一括更新するときは `firebase remoteconfig:get -P <project>` で現行テンプレートを取得し、
   `parameters` に出力された断片を足してから `firebase deploy --only remoteconfig`。
   **テンプレートは全パラメータを上書きするので、必ず現行の取得結果に足す形にすること。**

> 現在の本番の値（算数・国語の2件）は、まだこのファイルに反映していない。
> コンソールの現行値を `docs/cross_promo_apps.json` に貼り、上の手順で検証してから運用を切り替える。

## 掲載リストに載せる項目

`id`（applicationId）/ `name` / `tagline` / `iconUrl`（Play の CDN など）/ `storeUrl` / `category`。公開を確認してから載せる（Play のページが 200 を返すこと）。

## 現在の状況（2026-10-09 確認）

- `kore1-6b58e` の Remote Config: 算数・国語の2件を投入済み。
- 公開済み: 小学コレ！算数 / 小学コレ！国語。
- 審査中のため未掲載（2026-10-09 時点で Play ページが 404 のため未公開と判断）: 社会（`com.yourwish.shougakukore.shakai2`）/ Card Rivals（`com.yourwish.cardrivals`）。公開後に追記。
- 導入済みアプリ: 算数 / 国語 / 社会（コード）。保護者ゲートは3アプリとも導入済み。

## 既知のずれ（要対応）（2026-10-10 更新）

解消済み:
- 5アプリ（国語・算数・社会・プログラミング・道徳）の `cross_promo_kit` は `v0.3.0` 固定。`shared_core` も v0.3.0 を参照（shared_core#79）。
- `dependency_overrides` は5アプリとも削除済み（国語#105 / 算数#123 / 社会#181 / プログラミング#171 / 道徳#69）。
  コミット済みの `pubspec.lock` が古い `shared_core` を指すアプリ（道徳・プログラミング）は、`flutter pub upgrade shared_core` で lock を更新してからマージした。
- 5アプリとも設定画面に保護者ゲートと `isChildDirected: true` を導入済み。
- 算数の未使用 `packages/`（`cross_promo_kit` / `shared_core`）は sansu-kore#124 で削除済み。
- 算数の `CrossPromoService.init()` は sansu-kore#121 で再有効化済み（`unawaited` で起動をブロックしない）。

未解消:
- 算数の `currentAppId`（`com.petitworksapps.shougakukore.sansu`）が、`kore1-6b58e` の掲載リストの `id` と一致するか未確認。不一致だと自アプリが自分のリストに出る。
- 実機での確認が未実施: 起動でクラッシュループが再発しないこと、紹介カードの表示、自アプリの除外、保護者ゲート後のストア遷移。
- 国語の CI `Build iOS (unsigned)` が失敗する（`build_runner` 未実行が原因とみられるが、今回のログでは未確認）。紹介機能とは無関係。対応は見送り中。
- 「ゲームで学ぶ都道府県」の組み込みは保留中。

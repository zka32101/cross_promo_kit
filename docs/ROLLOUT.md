# 全アプリ展開の方針（2026-10-05 決定）

## 決定事項

1. **対象は Google Play 公開済みのアプリのみ。** 審査中・非公開のアプリは、公開後に Remote Config のリストへ追加する（コード側の導入は先行してよい）。
2. **紹介は同じシリーズ内だけ。** `category` が一致するアプリ同士で紹介する。
   - `小学コレ` … 算数 / 国語 / 社会 / 理科 / 英語 / プログラミング / 心身 など
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

## 掲載リストに載せる項目

`id`（applicationId）/ `name` / `tagline` / `iconUrl`（Play の CDN など）/ `storeUrl` / `category`。公開を確認してから載せる（Play のページが 200 を返すこと）。

## 現在の状況（2026-10-09 確認）

- `kore1-6b58e` の Remote Config: 算数・国語の2件を投入済み。
- 公開済み: 小学コレ！算数 / 小学コレ！国語。
- 審査中のため未掲載（2026-10-09 時点で Play ページが 404 のため未公開と判断）: 社会（`com.yourwish.shougakukore.shakai2`）/ Card Rivals（`com.yourwish.cardrivals`）。公開後に追記。
- 導入済みアプリ: 算数 / 国語 / 社会（コード）。保護者ゲートは3アプリとも導入済み。

## 既知のずれ（要対応）（2026-10-09 更新）

解消済み（3アプリとも `cross_promo_kit` は `v0.2.0` 固定、設定画面に保護者ゲート導入済み）:
- 社会: 導入時点で対応済み。
- 国語: kokugo-kore#100 で保護者ゲートの追加と、ホーム画面の `currentAppId`（仮値）の本番値への修正を反映。
- 算数: sansu-kore#120 で `dependency_overrides` により v0.2.0 に固定し、保護者ゲート・`currentCategory`・`currentAppId` を設定。

未解消:
- 算数の `currentAppId`（`com.petitworksapps.shougakukore.sansu`）が、`kore1-6b58e` の掲載リストの `id` と一致するか未確認。不一致だと自アプリが自分のリストに出る。
- 算数の `lib/main.dart` で `CrossPromoService.init()` がコメントアウトされたまま（「クラッシュループの可能性」の TODO）。原因を調べて有効化しないと、紹介カードに掲載アプリが出ない可能性がある。
- 算数の `packages/cross_promo_kit` と `packages/shared_core` は、ルートの `pubspec.yaml` から参照されておらずビルドで使われていないように見える。削除の可否を判断する。
- 国語の CI `Build iOS (unsigned)` が、`build_runner` 未実行（`*.g.dart` が `.gitignore` 対象）で PR 時に失敗する。紹介機能とは無関係。対応は見送り中。
- 3アプリとも、実機での表示確認（紹介カード、自アプリの除外、保護者ゲート後のストア遷移）は未実施。

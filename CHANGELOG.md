# Changelog

すべてのブロックの重要な変更は以下の形式で記載されます：

[Unreleased] - まだリリースされていない変更  
[X.X.X] - YYYY-MM-DD - リリース済みのバージョン

---

## [Unreleased]

### Added
- `CrossPromoSection.isChildDirected`: `true` のとき `beforeOpenStore`（保護者ゲート）が無いとデバッグビルドの assert で落ちる。
  子ども向けアプリでの渡し忘れを開発中に検知する。既定は `false`（従来どおり）。
- `CrossPromoSection.onOpenStore`: ゲート通過後・ストアを開く直前に呼ばれる任意のフック（タップ計測用）。例外は握りつぶす。
- デバッグビルドで、掲載リストが空でないのに `currentAppId` がどの `id` にも一致しないときに警告を出す。
- `tools/cross_promo_list.py`（掲載リストの検証・Remote Config 投入用の値の生成）と `docs/cross_promo_apps.json`（掲載リストの正）。

### Changed
- `CrossPromoSection` は Remote Config の取得完了時に自動で再描画する。
  アプリ側は `CrossPromoService.init()` を待たずに（`unawaited` で）呼んでも、取得後にカードが出る。

## [0.2.0] - 2026-10-01

### Added
- `CrossPromoSection` に `beforeOpenStore` を追加。ストアを開く前に保護者ゲートを挟めるようにした
  （子ども向けアプリでは必須: App Store ガイドライン 1.3 / Google Play ファミリーポリシー）。
  未指定時の動作は従来どおり。

### Changed
- 参照方法を `ref: main` からタグ固定（`ref: v0.2.0`）に変更（README）。
  アプリ側は必ずタグで参照し、戻す場合は ref を前のタグ（例: v0.1.0）に戻す。

## [0.1.0] - 2026-09-12

### Added
- 🔄 **Phase 4.17**: Cloud Functions サービス実装
  - Firestore を使ったクロスプロモーション管理
  - Firebase Remote Config との統合
  - URL Launcher による外部アプリ起動機能
- ✅ Initial cross-promotion package for Petit Works portfolio
  - Unified cross-app promotion framework
  - Minimal dependencies (firebase_remote_config, url_launcher only)
  - Version-agnostic Firebase integration (compatible with both firebase_core 2.x and 3.x)

### Dependencies
- `flutter: sdk`
- `firebase_remote_config: >=4.0.0 <7.0.0`
- `url_launcher: >=6.0.0 <7.0.0`
- `flutter_lints: ^6.0.0` (dev)

---

## Contributing

本パッケージは小学コレシリーズの共通クロスプロモーション機能を提供します。
Phase 4.23 以降の統合作業に対応しています。

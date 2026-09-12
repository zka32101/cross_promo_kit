# Changelog

すべてのブロックの重要な変更は以下の形式で記載されます：

[Unreleased] - まだリリースされていない変更  
[X.X.X] - YYYY-MM-DD - リリース済みのバージョン

---

## [Unreleased]

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

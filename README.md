# cross_promo_kit

Petit Works apps 全体で使うクロスプロモーション（他アプリ紹介）共通パッケージです。

## 目的

各アプリ（kokugo-kore, social_quiz_app, 今後追加される他アプリ）や `shared_core` パッケージから、
Firebase Remote Config で配信するプロモーション設定をもとに「他アプリの紹介」UIを共通化するためのパッケージです。

## 設計方針

- 依存は `firebase_remote_config` と `url_launcher` のみに限定しています。
- `firebase_remote_config` は各アプリの Firebase メジャーバージョン（`firebase_core` 2.x / 3.x など）と
  共存できるよう、意図的に広いバージョンレンジ（`>=4.0.0 <7.0.0`）を指定しています。
  pub の version solver が各アプリ側の制約と両立する具体バージョンを自動選択します。
- このレンジは各アプリ・`shared_core` 側の制約と衝突しないための設計上の要であるため、
  変更する場合は依存元アプリ全体への影響を確認してください。

## 利用方法

各アプリや `shared_core` の `pubspec.yaml` から git dependency として参照してください。

```yaml
dependencies:
  cross_promo_kit:
    git:
      url: https://github.com/zka32101/cross_promo_kit
      ref: main
```

## 構成

```
lib/
  cross_promo_kit.dart          # エントリポイント（公開API）
  models/
    promoted_app.dart           # 紹介するアプリの情報モデル
  services/
    cross_promo_service.dart    # Remote Config からのプロモーション情報取得
  widgets/
    cross_promo_section.dart    # 紹介UIウィジェット
```

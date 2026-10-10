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

必ずタグ（`ref: vX.Y.Z`）で固定してください。`main` は参照しません（戻せなくなるため）。

```yaml
dependencies:
  cross_promo_kit:
    git:
      url: https://github.com/zka32101/cross_promo_kit
      ref: v0.2.0
```

## 子ども向けアプリでの使い方

`isChildDirected: true` と `beforeOpenStore`（保護者ゲート）を必ずセットで渡してください。
渡し忘れるとデバッグビルドで assert が落ちます。

```dart
CrossPromoSection(
  currentAppId: '<本番の applicationId>',
  currentCategory: '小学コレ',
  isChildDirected: true,
  beforeOpenStore: (context) => requireParentalGate(context),
)
```

`CrossPromoService.init()` は `unawaited(CrossPromoService.init())` で起動をブロックせずに呼べます
（取得完了後にカードが自動で表示されます）。

## 掲載リストの管理

掲載リストの正は `docs/cross_promo_apps.json` です。検証と投入手順は `docs/ROLLOUT.md` を参照してください。

```
python3 tools/cross_promo_list.py validate --check-urls
python3 tools/cross_promo_list.py snippet
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

## 子ども向けアプリでの注意

外部ストアへのリンクの前には保護者ゲートが必須です。shared_core の `requireParentalGate` を渡してください。

```dart
CrossPromoSection(
  currentAppId: 'kokugo-kore',
  beforeOpenStore: (context) => requireParentalGate(context),
)
```

方針全体は shared_core の `docs/DEV_PLAYBOOK.md` を参照してください。

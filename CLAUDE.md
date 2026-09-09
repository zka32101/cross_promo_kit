# Cross Promo Kit — Claude Code 開発ガイド

## プロジェクト概要

**Cross Promo Kit** は、小学コレシリーズ全アプリで使用するクロスプロモーション（他アプリ紹介）共通パッケージです。

### 基本情報

- **パッケージ名**: `cross_promo_kit`
- **説明**: Firebase RemoteConfig と url_launcher のみに依存する軽量パッケージ。各アプリの Firebase バージョン（2.x/3.x）と完全に独立
- **リポジトリ**: GitHub（git dependency で各アプリから参照）
- **バージョン**: 0.1.0（開発中）

### 依存性

意図的に広いバージョン指定により、各アプリの Firebase メジャーバージョンに依らず共存可能：

```yaml
dependencies:
  firebase_remote_config: ">=4.0.0 <7.0.0"
  url_launcher: ">=6.0.0 <7.0.0"
```

> **理由**: Pub Version Solver が各アプリの制約と両立する具体バージョンを自動選択し、Firebase 2.x/3.x どちらでも動作

---

## 目的

1. **他アプリの紹介バナー表示**: ホーム画面・結果画面など各所にクロスプロモバナーを表示
2. **共通 UI/UX**: 小学コレシリーズ全体で統一された紹介体験を実現
3. **動的な紹介内容管理**: Firebase RemoteConfig でサーバー側から紹介内容・順序・表示判定をコントロール
4. **App Store/Google Play 誘導**: url_launcher で各プラットフォームのストアページへシームレス誘導

---

## 使用方法

### 1. 依存性の追加

各アプリの `pubspec.yaml` に git dependency を追加：

```yaml
dependencies:
  cross_promo_kit:
    git:
      url: https://github.com/zka32101/cross_promo_kit.git
      ref: main
```

### 2. Firebase RemoteConfig 初期化

アプリの `main.dart` で Firebase を初期化した後、RemoteConfig を fetch：

```dart
import 'package:cross_promo_kit/cross_promo_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // RemoteConfig の初期化
  final promo = CrossPromoManager.instance;
  await promo.fetchPromoConfig();
  
  runApp(const MyApp());
}
```

### 3. ウィジェットで表示

ホーム画面やストーリー結果画面などで：

```dart
import 'package:cross_promo_kit/cross_promo_kit.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // ... 既存コンテンツ
        
        // クロスプロモバナー
        const CrossPromoWidget(),
      ],
    );
  }
}
```

### 4. App Store/Google Play へ誘導

ユーザーが紹介バナーをタップした時、自動的に以下を実行：

```dart
// CrossPromoWidget 内部で自動実行
await CrossPromoManager.instance.openAppStore(
  packageName: 'com.example.sansu_kore',
  appStoreId: '1234567890',  // iOS の App Store ID
);
```

---

## 主要クラス・関数

### `CrossPromoManager`

クロスプロモの中枢。シングルトンパターンで全アプリから共有：

```dart
class CrossPromoManager {
  static final instance = CrossPromoManager._();
  
  // RemoteConfig から紹介内容を取得・キャッシュ
  Future<void> fetchPromoConfig() async { ... }
  
  // 取得した紹介内容のリスト
  List<PromoApp> get promoApps { ... }
  
  // 特定のアプリを紹介リストから取得
  PromoApp? getPromoApp(String appId) { ... }
  
  // Google Play/App Store へ誘導
  Future<void> openAppStore({
    required String packageName,
    String? appStoreId,  // iOS の場合は必須
  }) async { ... }
}
```

### `CrossPromoWidget`

バナー表示ウィジェット。RemoteConfig から取得した紹介内容を自動表示：

```dart
class CrossPromoWidget extends ConsumerWidget {
  const CrossPromoWidget({
    Key? key,
    this.maxAppsToShow = 3,
    this.height = 120.0,
  }) : super(key: key);
  
  // 表示するアプリ数
  final int maxAppsToShow;
  
  // バナーの高さ
  final double height;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

### `PromoApp` (データモデル)

RemoteConfig から解析される紹介アプリの情報：

```dart
class PromoApp {
  final String appId;              // e.g., 'com.example.sansu_kore'
  final String name;               // e.g., '算数コレ！'
  final String description;        // e.g., '算数を楽しく学ぼう！'
  final String? iconUrl;           // 紹介画像の URL
  final String? rating;            // ★★★★★ など（オプション）
  final bool enabled;              // この紹介を表示するか
}
```

### `fetchPromoConfig()`

Firebase RemoteConfig から紹介内容を非同期で取得：

```dart
Future<void> fetchPromoConfig() async {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    
    // デフォルト値を設定（失敗時のフォールバック）
    await remoteConfig.setDefaults({
      'promo_config': '{"enabled": false, "apps": []}',
    });
  } catch (e) {
    // ネットワークエラーでも、ローカルキャッシュを使用
    debugPrint('RemoteConfig fetch failed: $e');
  }
}
```

---

## Firebase RemoteConfig 設定例

Firebase Console の RemoteConfig で、以下の JSON を設定：

### パラメータ名: `promo_config`

```json
{
  "enabled": true,
  "apps": [
    {
      "app_id": "com.example.sansu_kore",
      "name": "算数コレ！",
      "description": "計算・図形・割合を楽しく学ぼう！",
      "icon_url": "https://example.com/sansu-icon.png",
      "rating": "★★★★★",
      "enabled": true
    },
    {
      "app_id": "com.example.kokugo_kore",
      "name": "国語コレ！",
      "description": "漢字・読解・作文の力を磨く",
      "icon_url": "https://example.com/kokugo-icon.png",
      "rating": "★★★★☆",
      "enabled": true
    },
    {
      "app_id": "com.example.eigo_kore",
      "name": "英語コレ！",
      "description": "小学英語をゲーム感覚で習得",
      "icon_url": "https://example.com/eigo-icon.png",
      "rating": null,
      "enabled": false
    }
  ]
}
```

### パラメータ設定項目

| パラメータ | 型 | 説明 | デフォルト |
|-----------|-----|------|----------|
| `enabled` | Boolean | クロスプロモ全体の有効/無効 | false |
| `apps` | Array | 紹介するアプリの配列 | [] |
| `apps[].app_id` | String | Google Play/App Store のパッケージ名 | 必須 |
| `apps[].name` | String | アプリ名 | 必須 |
| `apps[].description` | String | 短い紹介文 | 必須 |
| `apps[].icon_url` | String | アプリアイコン画像の URL（512x512推奨） | null |
| `apps[].rating` | String | ユーザー評価（★表記）| null |
| `apps[].enabled` | Boolean | このアプリの紹介を表示するか | true |

---

## セットアップ

### 1. Firebase RemoteConfig コンソール設定

1. [Firebase Console](https://console.firebase.google.com) にアクセス
2. 対象プロジェクト → Remote Config
3. **新しいパラメータを作成** をクリック
4. パラメータ名: `promo_config`
5. タイプ: JSON
6. デフォルト値を上記の JSON に設定
7. 条件（オプション）: 地域・ユーザーセグメント別に異なる紹介内容を配信可能
8. **公開** をクリック

### 2. 各アプリの pubspec.yaml に追加

```yaml
dependencies:
  cross_promo_kit:
    git:
      url: https://github.com/zka32101/cross_promo_kit.git
      ref: main
```

実行:
```bash
flutter pub get
```

### 3. main.dart で初期化

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cross_promo_kit/cross_promo_kit.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // RemoteConfig を fetch（アプリ起動時に実行）
  final promo = CrossPromoManager.instance;
  await promo.fetchPromoConfig();
  
  runApp(const MyApp());
}
```

### 4. ホーム画面に CrossPromoWidget を配置

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('ホーム')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... 既存のホーム画面コンテンツ
            
            const SizedBox(height: 24),
            const CrossPromoWidget(maxAppsToShow: 3),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
```

---

## 互換性・設計原則

### 1. Version Conflict 回避

**広いバージョン指定**により、各アプリの Firebase 世代に依らず共存：

```yaml
# Cross Promo Kit の pubspec.yaml
firebase_remote_config: ">=4.0.0 <7.0.0"

# 各アプリ例
# sansu-kore: firebase_core: ">=0.1.0" (firebase_remote_config 5.x と互換)
# kokugo-kore: firebase_core: ">=0.1.0" (firebase_remote_config 6.x と互換)
```

Pub Version Solver が自動的に各アプリと両立するバージョンを選択。

### 2. 各アプリ独立した Firebase 設定を保持

Cross Promo Kit は Firebase SDK 設定を持たず、各アプリの Firebase 初期化に依存：

```dart
// 各アプリで独立して Firebase 初期化
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// Cross Promo Kit は既に初期化された Firebase を利用
await CrossPromoManager.instance.fetchPromoConfig();
```

### 3. RemoteConfig がなくても基本動作（デグラデーション）

ネットワークエラーや初期化失敗時も、アプリがクラッシュしないよう設計：

```dart
try {
  await promo.fetchPromoConfig();
} catch (e) {
  // ローカルキャッシュまたはデフォルト値を使用
  debugPrint('RemoteConfig fetch failed, using defaults');
}

// CrossPromoWidget は gracefully 動作
// (promo_config がない場合は何も表示しない)
```

### 4. パッケージの責務範囲

✅ **含む**:
- RemoteConfig からの紹介内容取得
- バナー UI 表示
- Google Play/App Store への誘導

❌ **含まない**:
- Analytics（各アプリが実装）
- A/B テスト（Firebase RemoteConfig の条件機能を利用）
- 課金・サブスク管理（各アプリが独立実装）

---

## トラブルシューティング

### RemoteConfig が反映されない

1. Firebase Console で **公開** を押したか確認
2. アプリをリスタートして `fetchPromoConfig()` を再実行
3. RemoteConfig のデバッグモードを有効化:
   ```dart
   final remoteConfig = FirebaseRemoteConfig.instance;
   await remoteConfig.setConfigSettings(
     RemoteConfigSettings(
       minimumFetchInterval: Duration.zero,  // デバッグ用（実運用では 12h など）
     ),
   );
   ```

### App Store へのリンクが動作しない

- iOS の **App Store ID** が正しいか確認（`pubspec.yaml` 参照）
- URL 形式: `https://apps.apple.com/app/id{appStoreId}`

### Google Play へのリンクが動作しない

- パッケージ名がマニフェストと一致しているか確認
- URL 形式: `market://details?id={packageName}`（インストール済み）または `https://play.google.com/store/apps/details?id={packageName}`（未インストール）

---

## 開発フロー

### 新機能追加時のチェックリスト

- [ ] `lib/` に新しいウィジェット/関数を追加
- [ ] `pubspec.yaml` の依存性を確認（firebase_remote_config, url_launcher のみ）
- [ ] バージョン制約を広く保つ（メジャーバージョン +1）
- [ ] テストを `test/` に追加
- [ ] Firebase RemoteConfig の設定例を CLAUDE.md に追加
- [ ] 各アプリで動作確認

### コミット・プッシュ

```bash
git add CLAUDE.md lib/ test/
git commit -m "feat: add CrossPromoWidget

新しいクロスプロモバナーウィジェットを追加
- RemoteConfig から動的に紹介内容を読み込み
- タップで Google Play/App Store へ誘導
- 各アプリの Firebase 版に依らず動作

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>"

git push origin claude/relaxed-brahmagupta-9tarv4
```

---

## 参考資料

- [Firebase RemoteConfig 公式ドキュメント](https://firebase.google.com/docs/remote-config)
- [url_launcher パッケージ](https://pub.dev/packages/url_launcher)
- [Dart/Flutter パッケージ開発](https://dart.dev/guides/libraries/create-library-packages)

---

**最終更新**: 2026-09-09  
**ステータス**: 🔨 開発中（v0.1.0）

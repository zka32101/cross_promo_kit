import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../models/promoted_app.dart';

/// Remote Config キー。値は PromotedApp.toJson() の配列を JSON エンコードしたもの。
/// 全アプリ共通のキーで、ポートフォリオ全体の紹介候補を1つのJSON配列にまとめて配信する。
/// 各アプリは currentAppId で自分を除外し、currentCategory で「同じシリーズ」に絞り込む。
///
/// 例:
/// [
///   {"id":"com.petitworksapps.shougakukore.sansu","name":"算数コレ！","tagline":"...",
///    "iconUrl":"...","storeUrl":"...","category":"小学コレ"},
///   {"id":"com.petitworksapps.nihonryoudodefense","name":"日本領土ディフェンス","tagline":"...",
///    "iconUrl":"...","storeUrl":"...","category":"パズル・ゲーム"}
/// ]
const kCrossPromoRemoteConfigKey = 'cross_promo_apps';

/// アプリ内クロスプロモーション用の紹介リストを Firebase Remote Config から取得するサービス。
class CrossPromoService {
  CrossPromoService._();

  static FirebaseRemoteConfig? _remoteConfig;

  /// アプリ起動時に一度呼ぶ。失敗しても例外を投げず、以降は空リストとして扱う。
  static Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 6),
        ),
      );
      await rc.setDefaults(const {kCrossPromoRemoteConfigKey: '[]'});
      await rc.fetchAndActivate();
      _remoteConfig = rc;
    } catch (_) {
      _remoteConfig = null;
    }
  }

  /// 紹介対象のアプリ一覧を返す。
  /// - [currentAppId] と一致するエントリは自アプリなので常に除外する。
  /// - [currentCategory] を渡すと、同じ category のアプリだけに絞り込む
  ///   （＝「類似するアプリ」を紹介）。null または空文字なら絞り込まず全件対象。
  static List<PromotedApp> getPromotedApps({
    required String currentAppId,
    String? currentCategory,
  }) {
    final raw = _remoteConfig?.getString(kCrossPromoRemoteConfigKey) ?? '[]';
    return parseApps(raw, currentAppId: currentAppId, currentCategory: currentCategory);
  }

  /// Remote Config の生JSON文字列から [PromotedApp] 一覧を組み立てる純粋関数。
  /// Firebase 初期化なしでロジック単体をテストできるよう分離している。
  static List<PromotedApp> parseApps(
    String rawJson, {
    required String currentAppId,
    String? currentCategory,
  }) {
    final normalizedCurrentId = _stripDebugSuffix(currentAppId);
    try {
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(PromotedApp.fromJson)
          .where((app) => app.id != normalizedCurrentId && app.storeUrl.isNotEmpty)
          .where((app) =>
              currentCategory == null ||
              currentCategory.isEmpty ||
              app.category == currentCategory)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// デバッグビルドは applicationIdSuffix (".debug" など) が付いた別パッケージ名で
  /// 実行されるため、Remote Config に登録された本番IDと文字列が一致しない。
  /// 自己紹介（自アプリが自分自身の紹介リストに出てしまう）を防ぐため、
  /// 既知のデバッグサフィックスを比較前に取り除く。
  static const _debugSuffixes = ['.debug', '.dev'];

  static String _stripDebugSuffix(String appId) {
    for (final suffix in _debugSuffixes) {
      if (appId.endsWith(suffix)) {
        return appId.substring(0, appId.length - suffix.length);
      }
    }
    return appId;
  }
}

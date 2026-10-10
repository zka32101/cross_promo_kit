import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

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

  /// Remote Config の取得が完了するたびに増える。[CrossPromoSection] がこれを監視して
  /// 自動で再描画する。アプリ側が直接使う必要はない。
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static final Set<String> _warnedIds = <String>{};

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
      revision.value++;
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
    assert(() {
      _warnIfCurrentAppUnlisted(raw, currentAppId);
      return true;
    }());
    return parseApps(raw, currentAppId: currentAppId, currentCategory: currentCategory);
  }

  /// デバッグビルド専用。掲載リストが空でないのに、[currentAppId] がどの `id` にも
  /// 一致しないときに警告する（仮の applicationId を渡している／リスト側の id が
  /// 違う、というずれの検知用）。公開前のアプリは載っていなくて当然なので、
  /// 警告のみで動作は変えない。同じ id につき1回だけ出す。
  static void _warnIfCurrentAppUnlisted(String rawJson, String currentAppId) {
    final normalizedCurrentId = _stripDebugSuffix(currentAppId);
    if (_warnedIds.contains(normalizedCurrentId)) return;
    try {
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      if (decoded.isEmpty) return;
      final listed = decoded
          .cast<Map<String, dynamic>>()
          .map((m) => m['id'] as String? ?? '')
          .contains(normalizedCurrentId);
      if (!listed) {
        _warnedIds.add(normalizedCurrentId);
        debugPrint(
          '[cross_promo_kit] currentAppId "$normalizedCurrentId" が掲載リストの '
          'どの id にも一致しません。applicationId とリストの id が合っているか、'
          '公開前のアプリでなければ確認してください。',
        );
      }
    } catch (_) {}
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

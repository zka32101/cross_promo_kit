import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/promoted_app.dart';
import '../services/cross_promo_service.dart';

/// 「他のアプリもチェック！」セクション。設定画面などに置く想定。
///
/// Remote Config から取得した [PromotedApp] 一覧を横スクロールのカードで表示する。
/// 紹介対象が0件（未配信・取得失敗・同カテゴリのアプリなし）の場合は何も表示しない。
///
/// アプリ固有のデザイントークンには依存せず、`Theme.of(context)` の
/// ColorScheme / TextTheme のみを使う。どのアプリにドロップインしても
/// そのアプリのテーマに自然に馴染む。
class CrossPromoSection extends StatelessWidget {
  const CrossPromoSection({
    super.key,
    required this.currentAppId,
    this.currentCategory,
    this.title = '他のアプリもチェック！',
    this.maxApps = 6,
    this.beforeOpenStore,
    @visibleForTesting this.appsOverride,
  });

  final String currentAppId;

  /// 指定すると同じ category のアプリ（＝類似アプリ）だけに絞り込む。
  final String? currentCategory;

  final String title;
  final int maxApps;

  /// ストアを開く直前に呼ばれるゲート。`false` を返すと開かない。
  ///
  /// 子ども向けアプリでは外部リンクの前に保護者ゲートが必須
  /// （App Store ガイドライン 1.3 / Google Play ファミリーポリシー）なので、
  /// shared_core の `requireParentalGate` を渡すこと:
  /// `beforeOpenStore: (context) => requireParentalGate(context)`
  final Future<bool> Function(BuildContext context)? beforeOpenStore;

  /// テスト専用: Remote Config を経由せず表示データを直接渡す。本番コードでは使わない。
  @visibleForTesting
  final List<PromotedApp>? appsOverride;

  @override
  Widget build(BuildContext context) {
    final apps = appsOverride ??
        CrossPromoService.getPromotedApps(
          currentAppId: currentAppId,
          currentCategory: currentCategory,
        );
    if (apps.isEmpty) return const SizedBox.shrink();

    final shown = apps.take(maxApps).toList();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shown.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _PromotedAppCard(
              app: shown[i],
              beforeOpenStore: beforeOpenStore,
            ),
          ),
        ),
      ],
    );
  }
}

class _PromotedAppCard extends StatelessWidget {
  const _PromotedAppCard({required this.app, this.beforeOpenStore});

  final PromotedApp app;
  final Future<bool> Function(BuildContext context)? beforeOpenStore;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(app.storeUrl);
    if (uri == null) return;
    final gate = beforeOpenStore;
    if (gate != null && !await gate(context)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 130,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: app.iconUrl.isNotEmpty
                        ? Image.network(
                            app.iconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _IconFallback(theme: theme),
                          )
                        : _IconFallback(theme: theme),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  app.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  app.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  const _IconFallback({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.apps, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

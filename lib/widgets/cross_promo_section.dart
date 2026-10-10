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
    this.isChildDirected = false,
    this.beforeOpenStore,
    this.onOpenStore,
    @visibleForTesting this.appsOverride,
  }) : assert(
          !isChildDirected || beforeOpenStore != null,
          'isChildDirected: true の場合は beforeOpenStore（保護者ゲート）が必須です。'
          'beforeOpenStore: (context) => requireParentalGate(context) を渡してください。',
        );

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

  /// 子ども向けアプリなら true にする。true のとき [beforeOpenStore] が null だと
  /// デバッグビルドの assert で落ちる（保護者ゲートの渡し忘れを開発中に検知するため）。
  final bool isChildDirected;

  /// ゲートを通過してストアを開く直前に呼ばれる（タップ計測などに使う任意のフック）。
  /// 例外は握りつぶされるので、ここで失敗してもストアは開く。
  /// 子ども向けアプリでは、収集する内容が各ストアの規約に反しないよう注意すること。
  final void Function(PromotedApp app)? onOpenStore;

  /// テスト専用: Remote Config を経由せず表示データを直接渡す。本番コードでは使わない。
  @visibleForTesting
  final List<PromotedApp>? appsOverride;

  @override
  Widget build(BuildContext context) {
    final override = appsOverride;
    if (override != null) return _buildList(context, override);
    // init() 完了（Remote Config 取得後）に自動で再描画する。
    // アプリ側は init() を待たずに（unawaited で）呼んでも、取得後にカードが出る。
    return ValueListenableBuilder<int>(
      valueListenable: CrossPromoService.revision,
      builder: (context, _, __) => _buildList(
        context,
        CrossPromoService.getPromotedApps(
          currentAppId: currentAppId,
          currentCategory: currentCategory,
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<PromotedApp> apps) {
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
              onOpenStore: onOpenStore,
            ),
          ),
        ),
      ],
    );
  }
}

class _PromotedAppCard extends StatelessWidget {
  const _PromotedAppCard({required this.app, this.beforeOpenStore, this.onOpenStore});

  final PromotedApp app;
  final Future<bool> Function(BuildContext context)? beforeOpenStore;
  final void Function(PromotedApp app)? onOpenStore;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(app.storeUrl);
    if (uri == null) return;
    final gate = beforeOpenStore;
    if (gate != null && !await gate(context)) return;
    try {
      onOpenStore?.call(app);
    } catch (_) {
      // 計測フックの失敗でストア遷移を止めない。
    }
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

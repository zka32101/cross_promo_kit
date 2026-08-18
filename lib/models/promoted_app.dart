/// クロスプロモーションで紹介する1アプリ分のデータ。
class PromotedApp {
  const PromotedApp({
    required this.id,
    required this.name,
    required this.tagline,
    required this.iconUrl,
    required this.storeUrl,
    this.category = '',
  });

  /// 各アプリの applicationId 等、ポートフォリオ内で一意な識別子。
  /// 自アプリを紹介リストから除外するために使う。
  final String id;
  final String name;
  final String tagline;
  final String iconUrl;
  final String storeUrl;

  /// 紹介グループ（例: "小学コレ" "パズル・ゲーム" "トリビア"）。
  /// CrossPromoService.getPromotedApps に currentCategory を渡すと、
  /// 同じ category のアプリだけに絞り込める（＝「類似するアプリ」を紹介）。
  final String category;

  factory PromotedApp.fromJson(Map<String, dynamic> json) {
    return PromotedApp(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
      storeUrl: json['storeUrl'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tagline': tagline,
        'iconUrl': iconUrl,
        'storeUrl': storeUrl,
        'category': category,
      };
}

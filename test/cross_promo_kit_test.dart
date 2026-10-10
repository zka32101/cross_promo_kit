import 'package:cross_promo_kit/cross_promo_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _json = '''
[
  {"id":"a","name":"A","tagline":"t","iconUrl":"","storeUrl":"https://example.com/a","category":"小学コレ"},
  {"id":"b","name":"B","tagline":"t","iconUrl":"","storeUrl":"https://example.com/b","category":"小学コレ"},
  {"id":"c","name":"C","tagline":"t","iconUrl":"","storeUrl":"https://example.com/c","category":"パズル・ゲーム"},
  {"id":"d","name":"D","tagline":"t","iconUrl":"","storeUrl":"","category":"小学コレ"}
]
''';

void main() {
  group('CrossPromoService.parseApps', () {
    test('自アプリ・同カテゴリ以外・storeUrl が空のものを除外する', () {
      final apps = CrossPromoService.parseApps(
        _json,
        currentAppId: 'a',
        currentCategory: '小学コレ',
      );
      expect(apps.map((e) => e.id), ['b']);
    });

    test('デバッグサフィックスを取り除いて自アプリを除外する', () {
      final apps = CrossPromoService.parseApps(_json, currentAppId: 'a.debug');
      expect(apps.map((e) => e.id), ['b', 'c']);
    });

    test('壊れた JSON は空リストになる', () {
      expect(CrossPromoService.parseApps('x', currentAppId: 'a'), isEmpty);
    });
  });

  group('CrossPromoSection', () {
    test('isChildDirected: true で beforeOpenStore が無いと assert で落ちる', () {
      expect(
        () => CrossPromoSection(currentAppId: 'a', isChildDirected: true),
        throwsAssertionError,
      );
    });

    test('isChildDirected: true でも beforeOpenStore があれば作れる', () {
      expect(
        () => CrossPromoSection(
          currentAppId: 'a',
          isChildDirected: true,
          beforeOpenStore: (_) async => true,
        ),
        returnsNormally,
      );
    });

    testWidgets('appsOverride のアプリをカード表示する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrossPromoSection(
              currentAppId: 'a',
              appsOverride: const [
                PromotedApp(
                  id: 'b',
                  name: 'アプリB',
                  tagline: 'せつめい',
                  iconUrl: '',
                  storeUrl: 'https://example.com/b',
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('アプリB'), findsOneWidget);
    });

    testWidgets('掲載が0件なら何も表示しない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrossPromoSection(currentAppId: 'a', appsOverride: const []),
          ),
        ),
      );
      expect(find.text('他のアプリもチェック！'), findsNothing);
    });
  });
}

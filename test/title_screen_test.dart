import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotoba_no_mori/main.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/title_screen.dart';
import 'package:kotoba_no_mori/forest_scene.dart';

void main() {
  test('旧データの初回案内フラグは未表示扱いで、ほかの記録を維持する', () {
    final original = Progress(mode: 3, coins: 100, ownedItems: {'tulip'});
    original.submit('あいう');
    final data = jsonDecode(original.encode()) as Map<String, dynamic>;
    data.remove('welcomeSeen');
    final restored = Progress.decode(jsonEncode(data));
    expect(restored.welcomeSeen, false);
    expect(restored.coins, 100);
    expect(restored.guesses, ['あいう']);
    expect(restored.ownedItems, {'tulip'});
    restored.welcomeSeen = true;
    expect(Progress.decode(restored.encode()).welcomeSeen, true);
  });

  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(411, 914),
  ]) {
    testWidgets('タイトル→初回案内→ホーム、再起動後は案内を省略する ${size.width}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
      final p = Progress(
        mode: 3,
        coins: 70,
        ownedItems: {'tulip'},
        reduceMotion: true,
        soundEnabled: false,
        largeText: true,
      );
      p.loginDate = Progress.dayKey(DateTime.now());
      p.loginDay = 2;
      p.submit('あいう');
      p.draft = 'さ';
      SharedPreferences.setMockInitialValues({'forest_progress': p.encode()});
      await tester.pumpWidget(const ForestApp());
      await tester.pumpAndSettle();
      expect(find.byType(ForestTitleScreen), findsOneWidget);
      expect(find.text('ことばの森'), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsNothing);
      expect(find.byIcon(Icons.local_florist), findsNothing);
      expect(find.text('ゆっくり、ひとことば。'), findsOneWidget);
      expect(find.byType(ForestScene), findsNothing);
      final title = find.byKey(const ValueKey('title-start'));
      await tester.ensureVisible(title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(find.text('ことばの森へようこそ！'), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome-message')), findsOneWidget);
      final start = find.byKey(const ValueKey('welcome-start'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.byType(ForestTitleScreen), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      final saved = Progress.decode(prefs.getString('forest_progress'));
      expect(saved.welcomeSeen, true);
      expect(saved.coins, 70);
      expect(saved.loginDay, 2);
      expect(saved.guesses, ['あいう']);
      expect(saved.draft, 'さ');
      expect(saved.ownedItems, {'tulip'});
      expect(saved.soundEnabled, false);
      expect(saved.reduceMotion, true);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const ForestApp());
      await tester.pumpAndSettle();
      expect(find.byType(ForestTitleScreen), findsOneWidget);
      await tester.ensureVisible(title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(find.byType(ForestTitleScreen), findsNothing);
      expect(find.byKey(const ValueKey('welcome-message')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('初回案内後に宝箱からログイン報酬を受け取り、同日二重取得しない', (tester) async {
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
    SharedPreferences.setMockInitialValues({
      'forest_progress': Progress(reduceMotion: true).encode(),
    });
    await tester.pumpWidget(const ForestApp());
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(Progress.decode(prefs.getString('forest_progress')).coins, 0);
    await tester.tap(find.byKey(const ValueKey('title-start')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('welcome-start')));
    await tester.tap(find.byKey(const ValueKey('welcome-start')));
    await tester.pumpAndSettle();
    expect(Progress.decode(prefs.getString('forest_progress')).coins, 0);
    expect(
      Progress.decode(prefs.getString('forest_progress')).welcomeSeen,
      true,
    );
    final chest = find.byKey(const ValueKey('daily-treasure-chest'));
    await tester.ensureVisible(chest);
    await tester.pumpAndSettle();
    await tester.tap(chest);
    await tester.pumpAndSettle();
    expect(Progress.decode(prefs.getString('forest_progress')).coins, 10);
    expect(Progress.decode(prefs.getString('forest_progress')).loginDay, 1);
    await tester.tap(find.text('とじる'));
    await tester.pumpAndSettle();
    await tester.tap(chest);
    await tester.pump();
    expect(Progress.decode(prefs.getString('forest_progress')).coins, 10);
    expect(find.text('毎日の宝箱'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotoba_no_mori/main.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/forest_scene.dart';
import 'package:kotoba_no_mori/fantasy_backdrop.dart';
import 'app_launch.dart';

void main() {
  for (final size in [const Size(360, 800), const Size(411, 914)]) {
    testWidgets('ホームの主要ボタンがスクロールなしで見え、専用配色を他画面に持ち込まない $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
      final p = Progress(
        mode: 3,
        welcomeSeen: true,
        reduceMotion: true,
        solved: 7,
        coins: 90,
        ownedItems: {'tulip'},
      );
      p.loginDate = Progress.dayKey(DateTime.now());
      p.loginDay = 1;
      SharedPreferences.setMockInitialValues({'forest_progress': p.encode()});
      await tester.pumpWidget(const ForestApp());
      await enterPastTitle(tester);
      await tester.pumpAndSettle();
      for (final text in [
        'あそぶ',
        '今日のことば',
        '1日1問',
        'わたしの森',
        'わたしの記録',
        'あそびかた',
      ]) {
        final button = findLabel(text);
        expect(button, findsOneWidget);
        final bounds = tester.getRect(button);
        expect(bounds.top, greaterThanOrEqualTo(0), reason: text);
        expect(bounds.bottom, lessThanOrEqualTo(size.height), reason: text);
      }
      expect(find.text('3文字・4文字・5文字をえらぶ'), findsNothing);
      expect(find.byType(ForestScene), findsNothing);
      expect(find.byType(FantasyBackdrop), findsOneWidget);
      await tester.tap(findLabel('わたしの森'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ForestScene>(find.byType(ForestScene)).homePalette,
        false,
      );
      final prefs = await SharedPreferences.getInstance();
      final saved = Progress.decode(prefs.getString('forest_progress'));
      expect(saved.coins, 90);
      expect(saved.solved, 7);
      expect(saved.ownedItems, {'tulip'});
      expect(tester.takeException(), isNull);
    });
  }
}

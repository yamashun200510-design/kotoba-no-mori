import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/kana_keyboard.dart';
import 'package:kotoba_no_mori/letter_board.dart';
import 'package:kotoba_no_mori/main.dart';
import 'app_launch.dart';

void main() {
  test(
    'old saves default to swipe and the setting round-trips without changing data',
    () {
      final p = Progress(coins: 123, draft: 'さ', ownedItems: {'tulip'});
      final old = jsonDecode(p.encode()) as Map<String, dynamic>
        ..remove('swipeKeyboard');
      final restored = Progress.decode(jsonEncode(old));
      expect(restored.swipeKeyboard, true);
      restored.swipeKeyboard = false;
      final again = Progress.decode(restored.encode());
      expect(again.swipeKeyboard, false);
      expect(again.coins, 123);
      expect(again.draft, 'さ');
      expect(again.ownedItems, {'tulip'});
    },
  );

  testWidgets(
    'tabs and swipe change pages; taps input once without moving pages',
    (tester) async {
      final letters = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: KanaKeyboard(
                text: '',
                full: false,
                showSwipeGuide: true,
                onLetter: letters.add,
                onChange: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('左右にスワイプできます'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('kana-あ'))).height,
        greaterThan(48),
      );
      await tester.tap(find.byKey(const ValueKey('kana-あ')));
      await tester.pumpAndSettle();
      expect(letters, ['あ']);
      expect(
        find.byKey(const ValueKey('kana-あ')).hitTestable(),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(const ValueKey('kana-pages')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      for (final letter in ['は', 'ま', 'や', 'ら', 'わ', 'ん', 'ー']) {
        expect(
          find.byKey(ValueKey('kana-$letter')).hitTestable(),
          findsOneWidget,
        );
      }
      expect(letters, ['あ']);
      await tester.tap(find.byKey(const ValueKey('kana-ん')));
      await tester.pumpAndSettle();
      expect(letters, ['あ', 'ん']);
      await tester.tap(find.byKey(const ValueKey('kana-tab-0')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('kana-あ')).hitTestable(),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'change display during puzzle keeps draft, saves choice and survives restart',
    (tester) async {
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      final p =
          Progress(mode: 3, welcomeSeen: true, reduceMotion: true, coins: 123)
            ..loginDate = Progress.dayKey(DateTime.now())
            ..loginDay = 1;
      SharedPreferences.setMockInitialValues({'forest_progress': p.encode()});
      await tester.pumpWidget(const ForestApp());
      await enterPastTitle(tester);
      await enterNormalPuzzle(tester);
      await tester.tap(find.text('3文字であそぶ'));
      await tester.pumpAndSettle();
      expect(find.text('左右にスワイプできます'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('kana-さ')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('keyboard-display-settings')));
      await tester.pumpAndSettle();
      expect(find.text('文字盤の表示方法'), findsOneWidget);
      expect(find.text('横スワイプ式'), findsOneWidget);
      expect(find.text('おすすめ'), findsOneWidget);
      expect(find.text('五十音すべて表示'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('keyboard-mode-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('とじる'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LetterBoard>(find.byKey(const ValueKey('draft-board')))
            .text,
        'さ',
      );
      expect(find.byKey(const ValueKey('kana-pages')), findsNothing);
      expect(find.text('文字盤設定'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final prefs = await SharedPreferences.getInstance();
      final saved = Progress.decode(prefs.getString('forest_progress'));
      expect(saved.swipeKeyboard, false);
      expect(saved.coins, 123);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const ForestApp());
      await enterPastTitle(tester);
      await enterNormalPuzzle(tester);
      expect(find.byKey(const ValueKey('kana-pages')), findsNothing);
      expect(
        tester
            .widget<LetterBoard>(find.byKey(const ValueKey('draft-board')))
            .text,
        'さ',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

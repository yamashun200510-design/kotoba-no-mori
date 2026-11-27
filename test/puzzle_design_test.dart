import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/main.dart';
import 'package:kotoba_no_mori/rabbit_mascot.dart';
import 'package:kotoba_no_mori/puzzle_backdrop.dart';
import 'package:kotoba_no_mori/letter_board.dart';
import 'app_launch.dart';

void main() {
  for (final sample in [
    (3, const Size(411, 914), false),
    (4, const Size(320, 640), true),
  ]) {
    testWidgets('${sample.$1}文字・${sample.$2}で操作部が画面内に収まり、誤答に反応する', (
      tester,
    ) async {
      tester.view.physicalSize = sample.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      final progress =
          Progress(mode: sample.$1, largeText: sample.$3, reduceMotion: true)
            ..welcomeSeen = true
            ..loginDate = Progress.dayKey(DateTime.now())
            ..loginDay = 1;
      SharedPreferences.setMockInitialValues({
        'forest_progress': progress.encode(),
      });
      await tester.pumpWidget(const ForestApp());
      await enterPastTitle(tester);
      await enterModePickerFromHome(tester);
      await tester.tap(find.text('${sample.$1}文字であそぶ'));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleBackdrop), findsOneWidget);
      expect(find.byKey(const ValueKey('compact-puzzle-scroll')), findsNothing);
      for (final key in ['draft-board', 'erase-letter', 'kana-あ']) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(sample.$2.height));
      }
      final kana = tester.getSize(find.byKey(const ValueKey('kana-あ')));
      expect(kana.height, greaterThanOrEqualTo(48));
      for (var i = 0; i < sample.$1; i++) {
        await tester.tap(find.byKey(const ValueKey('kana-あ')));
        await tester.pump();
      }
      expect(
        tester
            .widget<LetterBoard>(find.byKey(const ValueKey('draft-board')))
            .text,
        'あ' * sample.$1,
      );
      await tester.tap(find.widgetWithText(FilledButton, '答える'));
      await tester.pumpAndSettle();
      final area = tester.getRect(find.byKey(const ValueKey('history-area')));
      final historyBoard = tester.getRect(
        find.byWidgetPredicate((w) => w is LetterBoard && w.marks != null).last,
      );
      expect(historyBoard.top, greaterThanOrEqualTo(area.top));
      expect(historyBoard.bottom, lessThanOrEqualTo(area.bottom));
      final rabbit = tester.widget<RabbitMascot>(
        find.byKey(const ValueKey('puzzle-companion')),
      );
      expect(rabbit.mood, RabbitMood.greeting);
      expect(rabbit.event, 1);
      expect(find.byKey(const ValueKey('wooden-hint-sign')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

import 'app_launch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotoba_no_mori/main.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/kana_keyboard.dart';
import 'package:kotoba_no_mori/first_steps.dart';
import 'package:kotoba_no_mori/letter_board.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });
  test('全問題の文字を五十音と変換で入力でき、カテゴリと長さが正しい', () {
    final reachable = kanaRows.join().characters.toSet();
    for (final c in reachable.toList()) {
      for (final change in KanaChange.values) {
        reachable.add(changeKana(c, change));
      }
    }
    const animals = {'うさぎ', 'きつね', 'りす', 'ふくろう', 'すずめ', 'かめ'};
    for (final word in words) {
      expect(word.text.length, inInclusiveRange(2, 6));
      expect(
        word.text.characters.every(reachable.contains),
        true,
        reason: word.text,
      );
      if (legacyWords.contains(word)) {
        expect(word.genre == 'どうぶつ', animals.contains(word.text));
      } else {
        expect(word.category, isNotEmpty);
        expect(word.declaredLength, word.text.length);
      }
      expect(judge(word.text, word.text).every((m) => m == Match.exact), true);
    }
  });

  test('重複判定で答えより多い個数に色を付けず、正位置を優先する', () {
    for (final answer in ['もも', 'ここあ', 'たんぽぽ', 'しろつめくさ']) {
      final guesses = [
        answer.split('').reversed.join(),
        'も' * answer.length,
        'ぽ' * answer.length,
      ];
      for (final guess in guesses) {
        final marks = judge(answer, guess);
        for (var i = 0; i < answer.length; i++) {
          expect(marks[i] == Match.exact, answer[i] == guess[i]);
        }
        for (final letter in guess.characters.toSet()) {
          final colored = List.generate(
            guess.length,
            (i) => i,
          ).where((i) => guess[i] == letter && marks[i] != Match.absent).length;
          expect(
            colored,
            lessThanOrEqualTo(
              answer.characters.where((c) => c == letter).length,
            ),
          );
        }
      }
    }
  });

  testWidgets('初回だけ練習でき、スキップ後は再起動しても再表示しない', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    expect(find.byType(FirstSteps), findsOneWidget);
    for (final letter in ['さ', 'く', 'ら']) {
      await tester.tap(find.widgetWithText(OutlinedButton, letter));
      await tester.pumpAndSettle();
    }
    expect(
      tester
          .widget<LetterBoard>(
            find.descendant(
              of: find.byType(FirstSteps),
              matching: find.byType(LetterBoard),
            ),
          )
          .text,
      'さくら',
    );
    await tester.ensureVisible(find.text('スキップ'));
    await tester.tap(find.text('スキップ'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(
      Progress.decode(prefs.getString('forest_progress')).introductionSeen,
      true,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(FirstSteps), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final config in [
    (const Size(568, 320), 1.0),
    (const Size(320, 568), 2.0),
  ]) {
    testWidgets('横画面・端末文字倍率${config.$2}でも入力と回答に到達できる', (tester) async {
      tester.view.physicalSize = config.$1;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = config.$2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final p = Progress(
        largeText: true,
        reduceMotion: true,
        loginDate: Progress.dayKey(DateTime.now()),
        loginDay: 1,
      );
      SharedPreferences.setMockInitialValues({'forest_progress': p.encode()});
      await tester.pumpWidget(const ForestApp());
      await enterPastTitle(tester);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('あそぶ'), 150);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('あそぶ'));
      await tester.pumpAndSettle();
      await enterNormalPuzzle(tester);
      final bottom = find.byKey(const ValueKey('erase-letter'));
      await tester.ensureVisible(bottom);
      await tester.pumpAndSettle();
      expect(bottom.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('振動のオンオフを保存し、未対応でも入力を妨げない', (tester) async {
    var clicks = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') clicks++;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    for (final enabled in [true, false]) {
      final p = Progress(
        hapticsEnabled: enabled,
        reduceMotion: true,
        loginDate: Progress.dayKey(DateTime.now()),
        loginDay: 1,
      );
      expect(Progress.decode(p.encode()).hapticsEnabled, enabled);
      SharedPreferences.setMockInitialValues({'forest_progress': p.encode()});
      await tester.pumpWidget(const ForestApp());
      await enterPastTitle(tester);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('あそぶ'), 150);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('あそぶ'));
      await tester.pumpAndSettle();
      await enterNormalPuzzle(tester);
      final before = clicks;
      await tester.tap(find.byKey(const ValueKey('kana-あ')));
      await tester.pumpAndSettle();
      expect(clicks - before, enabled ? 1 : 0);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

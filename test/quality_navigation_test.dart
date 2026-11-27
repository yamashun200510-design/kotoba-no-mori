import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotoba_no_mori/main.dart';
import 'package:kotoba_no_mori/game.dart';
import 'app_launch.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    Size size, {
    bool large = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    final p = Progress(mode: 3, largeText: large, reduceMotion: true)
      ..welcomeSeen = true
      ..loginDate = Progress.dayKey(DateTime.now())
      ..loginDay = 1;
    SharedPreferences.setMockInitialValues({'forest_progress': p.encode()});
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(390, 844), const Size(411, 914)]) {
    testWidgets('$size のホームで目標と宝箱が見え、森の成長メッセージを重ねない', (tester) async {
      await open(tester, size);
      for (final text in ['あそぶ', '今日のことば', '1日1問', '今日の目標 0/3問 ・ 達成で30コイン']) {
        final rect = tester.getRect(findLabel(text));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
      }
      final chest = tester.getRect(
        find.byKey(const ValueKey('daily-treasure-chest')),
      );
      expect(chest.top, greaterThanOrEqualTo(0));
      expect(chest.bottom, lessThanOrEqualTo(size.height - 24));
      expect(find.text('ひとつ解くたび、森が育つ。'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('森から直前のパズルへ戻り、Androidの戻る操作でも入力を保持する', (tester) async {
    await open(tester, const Size(411, 914));
    await enterModePickerFromHome(tester);
    await tester.tap(find.text('3文字であそぶ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kana-あ')));
    await tester.pump();
    // A solved screen provides this same navigation action.
    final state = tester.state(find.byType(ForestApp)) as dynamic;
    state.go('わたしの森');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('previous-page')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('draft-board')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('3文字であそぶ'), findsOneWidget);
    await tester.tap(find.text('3文字であそぶ'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(Progress.decode(prefs.getString('forest_progress')).draft, 'あ');
    expect(tester.takeException(), isNull);
  });
}

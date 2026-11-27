import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotoba_no_mori/main.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/rabbit_sendoff.dart';
import 'app_launch.dart';

void main() {
  Future<void> openModes(WidgetTester tester, {bool quiet = false}) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    final progress = Progress(coins: 123, mode: 3, reduceMotion: quiet)
      ..welcomeSeen = true
      ..loginDate = Progress.dayKey(DateTime.now())
      ..loginDay = 1;
    SharedPreferences.setMockInitialValues({
      'forest_progress': progress.encode(),
    });
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await enterModePickerFromHome(tester);
  }

  testWidgets('見送り中は連打を遮り、1.2秒後だけモードを変更する', (tester) async {
    await openModes(tester);
    final prefs = await SharedPreferences.getInstance();
    await tester.tap(find.text('4文字であそぶ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(RabbitSendoff), findsOneWidget);
    expect(find.text('いってらっしゃい！'), findsOneWidget);
    expect(Progress.decode(prefs.getString('forest_progress')).mode, 3);
    await tester.tap(find.text('3文字であそぶ'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(RabbitSendoff), findsNothing);
    final saved = Progress.decode(prefs.getString('forest_progress'));
    expect(saved.mode, 4);
    expect(saved.coins, 123);
    expect(tester.takeException(), isNull);
  });

  testWidgets('戻ると見送りを取り消し、遅れて遷移しない', (tester) async {
    await openModes(tester);
    await tester.tap(find.text('4文字であそぶ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(RabbitSendoff), findsNothing);
    expect(find.text('4文字であそぶ'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(Progress.decode(prefs.getString('forest_progress')).mode, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('動きを減らす設定では見送りを省略してすぐ開始する', (tester) async {
    await openModes(tester, quiet: true);
    await tester.tap(find.text('4文字であそぶ'));
    await tester.pump();
    expect(find.byType(RabbitSendoff), findsNothing);
    expect(find.text('4文字であそぶ'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(Progress.decode(prefs.getString('forest_progress')).mode, 4);
    expect(tester.takeException(), isNull);
  });
}

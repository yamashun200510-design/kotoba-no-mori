import 'app_launch.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/main.dart';

void main() {
  test('全体・最高連続・日別成績は保存された事実だけで集計し再起動後も保持する', () {
    var p = Progress(mode: 3, solved: 7, todayClears: {'2026-10-20'});
    final now = DateTime(2026, 10, 23);
    p.submit('あいう', now: now);
    p.submit(p.word.text, now: now);
    p.next();
    p.selectMode(4);
    p.submit(p.word.text, now: now);
    p.refreshDay(now);
    p.submitToday(p.today.word.text, now: now);
    final snapshot = p.encode();
    p = Progress.decode(snapshot);
    final stats = p.performance;
    expect(stats.lifetimeClears, p.totalSolved);
    expect(stats.overall.clears, 3);
    expect(stats.overall.averageAttempts, closeTo(4 / 3, .00001));
    expect(stats.overall.streak, 3);
    expect(stats.overall.bestStreak, 3);
    expect(
      stats.forLength(3).clears,
      p.records.where((r) => r.length == 3).length,
    );
    expect(
      stats.forLength(4).clears,
      p.records.where((r) => r.length == 4).length,
    );
    expect(stats.dailyDatesNewestFirst, ['2026-10-23', '2026-10-20']);
    expect(stats.dailyRecord('2026-10-20'), isNull);
    expect(stats.dailyRecord('2026-10-23')!.attempts, 1);
    expect(p.submitToday(p.today.word.text, now: now), false);
    expect(p.performance.overall.clears, 3);
    expect(p.encode(), snapshot);
  });

  test('履歴のない成績は平均未計算・連続ゼロで、既存累計とクリア日を維持する', () {
    final p = Progress(solved: 20, todayClears: {'2026-10-01'});
    final stats = Progress.decode(p.encode()).performance;
    expect(stats.lifetimeClears, 21);
    expect(stats.overall.averageAttempts, isNull);
    expect(stats.overall.streak, 0);
    expect(stats.overall.bestStreak, 0);
    expect(stats.forLength(3).clears, 0);
    expect(stats.forLength(4).clears, 0);
    expect(stats.dailyRecord('2026-10-01'), isNull);
  });
  test('正解だけを数え、平均・連続数をモード別に保存する', () {
    var p = Progress(mode: 3);
    expect(p.statistics(3).averageAttempts, isNull);
    expect(p.submit('あ'), false);
    p.submit('あいう');
    p.submit('かきく');
    expect(p.records, isEmpty);
    p = Progress.decode(p.encode());
    p.submit(p.word.text);
    expect(p.records.single.attempts, 3);
    expect(p.statistics(3).clears, 1);
    expect(p.statistics(3).averageAttempts, 3);
    expect(p.statistics(3).streak, 1);
    final coins = p.coins;
    expect(p.submit(p.word.text), false);
    p = Progress.decode(p.encode());
    expect(p.submit(p.word.text), false);
    expect(p.records.length, 1);
    expect(p.coins, coins);
    p.next();
    p.submit(p.word.text);
    expect(p.statistics(3).averageAttempts, 2);
    expect(p.statistics(3).streak, 2);
    p.selectMode(4);
    p.submit('あいうえ');
    p.submit(p.word.text);
    p = Progress.decode(p.encode());
    expect(p.statistics(4).clears, 1);
    expect(p.statistics(4).averageAttempts, 2);
    expect(p.statistics(3).clears, 2);
    expect(p.records.map((r) => r.id).toSet().length, 3);
  });

  test('同じ単語の別周回は別の解答記録になり、同じクリアの再処理は増えない', () {
    var p = Progress(
      mode: 3,
      modes: {
        3: ModePuzzle(3, order: ['さくら']),
      },
    );
    p.submit('さくら');
    p.next();
    p.submit('あいう');
    p.submit('さくら');
    expect(p.records.length, 2);
    expect(p.statistics(3).averageAttempts, 1.5);
    p = Progress.decode(p.encode());
    expect(p.submit(p.word.text), false);
    expect(p.records.length, 2);
  });

  test('今日のことばは日付ごとに一度だけ記録し通常問題の途中経過を保つ', () {
    var p = Progress(mode: 3);
    p.submit('あいう');
    final now = DateTime(2026, 10, 23);
    p.refreshDay(now);
    p.submitToday(p.today.word.text, now: now);
    expect(p.records.single.source, 'daily');
    expect(p.records.single.attempts, 1);
    p = Progress.decode(p.encode());
    expect(p.submitToday(p.today.word.text, now: now), false);
    expect(p.records.length, 1);
    expect(p.guesses, ['あいう']);
    final next = now.add(const Duration(days: 1));
    p.refreshDay(next);
    p.submitToday(p.today.word.text, now: next);
    expect(p.records.length, 2);
  });

  test('旧セーブの正解済み問題は遡って推測集計せず、次の問題から記録する', () {
    final original = Progress(
      mode: 3,
      coins: 100,
      ownedItems: {'tulip'},
      solved: 7,
    );
    original.submit(original.word.text);
    final data = jsonDecode(original.encode()) as Map<String, dynamic>;
    data.remove('records');
    data.remove('legacyClearRecorded');
    (data['modes']['3'] as Map).remove('clearRecorded');
    final p = Progress.decode(jsonEncode(data));
    expect(p.records, isEmpty);
    expect(p.won, true);
    expect(p.coins, original.coins);
    expect(p.totalSolved, original.totalSolved);
    expect(p.ownedItems, {'tulip'});
    expect(p.submit(p.word.text), false);
    p.next();
    p.submit(p.word.text);
    expect(p.records.length, 1);
  });

  test('壊れた任意の記録があってもコインと途中データを初期化しない', () {
    final p = Progress(mode: 4, coins: 90, draft: '', largeText: true);
    p.submit('あいうえ');
    final data = jsonDecode(p.encode()) as Map<String, dynamic>;
    const good = PuzzleRecord(
      id: 1,
      word: 'さくら',
      length: 3,
      attempts: 2,
      date: '2026-10-23',
      source: 'normal',
    );
    data['records'] = [
      null,
      {'id': -1},
      good.encode(),
      good.encode(),
    ];
    final restored = Progress.decode(jsonEncode(data));
    expect(restored.coins, 90);
    expect(restored.guesses, ['あいうえ']);
    expect(restored.largeText, true);
    expect(restored.records.length, 1);
  });

  for (final size in [const Size(320, 568), const Size(411, 914)]) {
    testWidgets('正解回数と詳細が${size.width}幅の大きめ文字でも読め、次へ進める', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
      final p = Progress(mode: 3, reduceMotion: true, largeText: true);
      p.loginDate = Progress.dayKey(DateTime.now());
      p.loginDay = 1;
      p.submit('あいう');
      p.submit('かきく');
      p.submit('さくら');
      SharedPreferences.setMockInitialValues({'forest_progress': p.encode()});
      await tester.pumpWidget(const ForestApp());
      await enterPastTitle(tester);
      await tester.pumpAndSettle();
      await enterNormalPuzzle(tester);
      expect(find.text('今回は3回で正解！'), findsOneWidget);
      expect(find.text('あなたの3文字の平均 3.0回'), findsOneWidget);
      final records = find.byKey(const ValueKey('show-records'));
      await tester.ensureVisible(records);
      await tester.tap(records);
      await tester.pumpAndSettle();
      expect(find.text('3.0回'), findsWidgets);
      final list = find.byKey(const ValueKey('records-list'));
      final recordScroll = find
          .descendant(of: list, matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        find.text('3文字の記録'),
        150,
        scrollable: recordScroll,
      );
      expect(find.text('3文字の記録'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('4文字の記録'),
        150,
        scrollable: find
            .descendant(of: list, matching: find.byType(Scrollable))
            .first,
      );
      await tester.scrollUntilVisible(
        find.text('今日のことばの記録'),
        150,
        scrollable: recordScroll,
      );
      await tester.scrollUntilVisible(
        find.text('正解した日を、ここに残します。'),
        100,
        scrollable: recordScroll,
      );
      expect(find.text('正解した日を、ここに残します。'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('とじる'));
      await tester.pumpAndSettle();
      final next = find.text('つぎの問題');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('今回は3回で正解！'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      final saved = Progress.decode(prefs.getString('forest_progress'));
      expect(saved.records.single.attempts, 3);
      expect(saved.word.text, 'うさぎ');
      expect(tester.takeException(), isNull);
    });
  }
}

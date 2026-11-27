import 'app_launch.dart';
import 'package:flutter/material.dart';
import 'package:kotoba_no_mori/forest_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotoba_no_mori/main.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/letter_board.dart';
import 'package:kotoba_no_mori/forest_scene.dart';
import 'package:kotoba_no_mori/kana_keyboard.dart';
import 'package:kotoba_no_mori/coin_badge.dart';
import 'package:kotoba_no_mori/success_petals.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    Progress? progress,
    bool settlePuzzle = true,
  }) async {
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
    final initial = progress ?? Progress(reduceMotion: true);
    // These regression fixtures exercise the preserved full-table layout.
    initial.swipeKeyboard = false;
    initial.loginDate = Progress.dayKey(DateTime.now());
    initial.loginDay = 1;
    SharedPreferences.setMockInitialValues({
      'forest_progress': initial.encode(),
    });
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    if (settlePuzzle) {
      await enterNormalPuzzle(tester);
    } else {
      final dynamic app = tester.state(find.byType(ForestApp));
      app.startNormal();
      await tester.pump(const Duration(milliseconds: 1400));
    }
  }

  Finder answer() => find.widgetWithText(FilledButton, '答える');

  testWidgets('初回起動後に宝箱を開け、同日再起動では再付与しない', (tester) async {
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
    SharedPreferences.setMockInitialValues({
      'forest_progress': Progress(reduceMotion: true).encode(),
    });
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    final chest = find.byKey(const ValueKey('daily-treasure-chest'));
    await tester.ensureVisible(chest);
    await tester.pumpAndSettle();
    expect(tester.widget<CoinBadge>(find.byType(CoinBadge)).coins, 0);
    await tester.tap(chest);
    await tester.pumpAndSettle();
    expect(find.text('宝箱をひらいたよ！'), findsOneWidget);
    expect(find.text('＋10 コイン！'), findsOneWidget);
    expect(tester.widget<CoinBadge>(find.byType(CoinBadge)).coins, 10);
    final prefs = await SharedPreferences.getInstance();
    expect(Progress.decode(prefs.getString('forest_progress')).loginDay, 1);
    await tester.tap(find.text('とじる'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    expect(tester.widget<CoinBadge>(find.byType(CoinBadge)).coins, 10);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ショップは矢印と横スワイプで切り替わり、購入を取り消せる', (tester) async {
    await open(tester, progress: Progress(coins: 500, reduceMotion: true));
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('わたしの森'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('わたしの森'));
    await tester.pumpAndSettle();
    final shopHouse = find.byKey(const ValueKey('forest-shop-house'));
    await tester.drag(find.byType(ListView).last, const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(shopHouse);
    await tester.pumpAndSettle();
    expect(find.text('森の小さなお店'), findsOneWidget);
    final carousel = find.byKey(const ValueKey('shop-carousel'));
    await tester.ensureVisible(find.byKey(const ValueKey('shop-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shop-next')));
    await tester.pumpAndSettle();
    var page = tester.widget<PageView>(carousel);
    expect(page.controller!.page, closeTo(1, .01));
    await tester.drag(carousel, const Offset(-400, 0));
    await tester.pumpAndSettle();
    page = tester.widget<PageView>(carousel);
    expect(page.controller!.page, closeTo(2, .01));
    final buy = find.descendant(
      of: find.byKey(const ValueKey('shop-sunflower')),
      matching: find.widgetWithText(FilledButton, '森に迎える'),
    );
    await tester.ensureVisible(buy);
    await tester.pumpAndSettle();
    await tester.tap(buy);
    await tester.pumpAndSettle();
    expect(find.textContaining('ひまわり\n80 コイン'), findsOneWidget);
    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();
    expect(tester.widget<CoinBadge>(find.byType(CoinBadge)).coins, 500);
    final prefs = await SharedPreferences.getInstance();
    expect(
      Progress.decode(prefs.getString('forest_progress')).ownedItems,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('コインは獲得時だけ増加表示し、使用時と動きを減らす設定では即時更新', (tester) async {
    Widget counter(int coins, {bool quiet = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: quiet),
        child: Scaffold(
          body: Center(child: CoinBadge(coins: coins)),
        ),
      ),
    );
    await tester.pumpWidget(counter(80));
    expect(find.text('80'), findsOneWidget);
    await tester.pumpWidget(counter(90));
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('coin-balance')))
          .properties
          .label,
      '所持コイン 90枚',
    );
    await tester.pump(const Duration(milliseconds: 120));
    final middle = int.parse(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byType(CoinBadge),
              matching: find.byType(Text),
            ),
          )
          .data!,
    );
    expect(middle, greaterThan(80));
    expect(middle, lessThan(90));
    await tester.pumpAndSettle();
    expect(find.text('90'), findsOneWidget);
    await tester.pumpWidget(counter(50));
    expect(find.text('50'), findsOneWidget);
    await tester.pumpWidget(counter(100, quiet: true));
    expect(find.text('100'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  Future<void> typeWord(WidgetTester tester, String text) async {
    for (final letter in text.characters) {
      var base = letter;
      KanaChange? conversion;
      if (!kanaRows.any((row) => row.contains(base))) {
        for (final change in KanaChange.values) {
          for (final candidate in kanaRows.join().characters) {
            if (changeKana(candidate, change) == letter &&
                candidate != letter) {
              base = candidate;
              conversion = change;
              break;
            }
          }
          if (conversion != null) break;
        }
      }
      final row = kanaRows.indexWhere((row) => row.contains(base));
      expect(row, greaterThanOrEqualTo(0));
      await tester.ensureVisible(find.byKey(ValueKey('kana-$base')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('kana-$base')));
      await tester.pumpAndSettle();
      if (conversion != null) {
        await tester.tap(find.byKey(ValueKey('change-${conversion.name}')));
        await tester.pumpAndSettle();
      }
    }
  }

  String draft(WidgetTester tester) => tester
      .widget<LetterBoard>(find.byKey(const ValueKey('draft-board')))
      .text;
  testWidgets('小画面・大きな文字でも購入でき、コインと配置を再起動後に復元する', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(
      tester,
      progress: Progress(
        coins: 80,
        solved: 4,
        largeText: true,
        reduceMotion: true,
      ),
    );
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('わたしの森'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('わたしの森'));
    await tester.pumpAndSettle();
    final shopHouse = find.byKey(const ValueKey('forest-shop-house'));
    await tester.drag(find.byType(ListView).last, const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(shopHouse);
    await tester.pumpAndSettle();
    final buy = find.descendant(
      of: find.byKey(const ValueKey('shop-tulip')),
      matching: find.widgetWithText(FilledButton, '森に迎える'),
    );
    await tester.ensureVisible(buy);
    await tester.pumpAndSettle();
    await tester.tap(buy);
    await tester.pumpAndSettle();
    expect(find.textContaining('チューリップ\n30 コイン'), findsOneWidget);
    await tester.tap(find.text('購入する'));
    await tester.pumpAndSettle();
    expect(tester.widget<CoinBadge>(find.byType(CoinBadge)).coins, 50);
    final afterPurchase = Progress.decode(
      (await SharedPreferences.getInstance()).getString('forest_progress'),
    );
    expect(afterPurchase.ownedItems, contains('tulip'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    expect(tester.widget<CoinBadge>(find.byType(CoinBadge)).coins, 50);
    await tester.ensureVisible(find.text('わたしの森'));
    await tester.tap(find.text('わたしの森'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ForestScene>(find.byType(ForestScene)).items,
      contains('tulip'),
    );
    final prefs = await SharedPreferences.getInstance();
    final restored = Progress.decode(prefs.getString('forest_progress'));
    expect(restored.ownedItems, {'tulip'});
    expect(restored.solved, 4);
  });

  testWidgets('3問目の正解で日次のお祝いと報酬を表示して次へ進める', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(
      tester,
      progress: Progress(
        solved: 2,
        coins: 20,
        reduceMotion: true,
        largeText: true,
        dailyDate: Progress.dayKey(DateTime.now()),
        dailyWords: {'さくら', 'うさぎ'},
        rewardedWords: {'さくら', 'うさぎ'},
      ),
    );
    await typeWord(tester, 'たんぽぽ');
    await tester.pumpAndSettle();
    await tester.tap(answer());
    await tester.pumpAndSettle();
    expect(find.text('今日の目標たっせい！ ＋30コイン'), findsOneWidget);
    expect(find.text('+10 コイン'), findsOneWidget);
    expect(tester.widget<CoinBadge>(find.byType(CoinBadge)).coins, 60);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('つぎの問題'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final restored = Progress.decode(prefs.getString('forest_progress'));
    expect(restored.coins, 60);
    expect(restored.dailyBonusGiven, true);
    expect(restored.solved, 3);
  });

  testWidgets('動きを減らす設定を保存し、ホームへ戻ると森の動きが止まる', (tester) async {
    await open(
      tester,
      progress: Progress(reduceMotion: false),
      settlePuzzle: false,
    );
    await tester.tap(find.text('ホーム'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('home-settings')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('動きを減らす'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('動きを減らす'));
    await tester.pump(const Duration(milliseconds: 200));
    final prefs = await SharedPreferences.getInstance();
    expect(
      Progress.decode(prefs.getString('forest_progress')).reduceMotion,
      true,
    );
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('文字を直接押すとマスに入り、文字数を超えず、回答と次の問題を保存', (tester) async {
    await open(tester);
    expect(find.byType(TextField), findsNothing);
    expect(tester.testTextInput.isVisible, false);
    expect(find.text(words.first.clue), findsNothing);
    await typeWord(tester, 'さ');
    expect(draft(tester), 'さ');
    final incomplete = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'あと2文字'),
    );
    expect(incomplete.onPressed, isNull);
    await typeWord(tester, 'くらあ');
    expect(draft(tester), 'さくら');
    await tester.tap(answer());
    await tester.pumpAndSettle();
    expect(find.text('せいかい！'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(Progress.decode(prefs.getString('forest_progress')).totalSolved, 1);
    await tester.tap(find.text('つぎの問題'));
    await tester.pumpAndSettle();
    expect(find.text('どうぶつ'), findsOneWidget);
    expect(find.byType(KanaKeyboard), findsOneWidget);
    expect(draft(tester), '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('五十音表を直接押せて、濁点・半濁点・小文字・削除を操作できる', (tester) async {
    await open(tester);
    expect(find.text('あ行'), findsNothing);
    for (var row = 0; row < kanaRows.length; row++) {
      for (final letter in kanaRows[row].characters) {
        final key = find.byKey(ValueKey('kana-$letter'));
        await tester.scrollUntilVisible(
          key,
          50,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('kana-table')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        expect(key.hitTestable(), findsOneWidget);
        expect(tester.getSize(key).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(key).height, greaterThanOrEqualTo(48));
      }
    }
    await typeWord(tester, 'ぱっぐ');
    expect(draft(tester), 'ぱっぐ');
    await tester.tap(find.byKey(const ValueKey('change-voiced')));
    await tester.pumpAndSettle();
    expect(draft(tester), 'ぱっく');
    await tester.tap(find.byKey(const ValueKey('erase-letter')));
    await tester.pumpAndSettle();
    expect(draft(tester), 'ぱっ');
    await tester.tap(find.byKey(const ValueKey('change-small')));
    await tester.pumpAndSettle();
    expect(draft(tester), 'ぱつ');
    expect(tester.testTextInput.isVisible, false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('五十音すべて表示では行切替なしで全キーにスクロール到達できる', (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 52, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await open(tester);
    expect(find.text('あ行'), findsNothing);
    expect(find.text('文字の一覧を上下にスクロール'), findsNothing);
    for (final letter in kanaRows.join().characters) {
      final key = find.byKey(ValueKey('kana-$letter'));
      await tester.scrollUntilVisible(
        key,
        50,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('kana-table')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(key.hitTestable(), findsOneWidget);
    }
    final a = tester.getRect(find.byKey(const ValueKey('kana-あ')));
    final i = tester.getRect(find.byKey(const ValueKey('kana-い')));
    final ka = tester.getRect(find.byKey(const ValueKey('kana-か')));
    expect(a.top, i.top);
    expect(a.left, ka.left);
    expect(ka.top, greaterThan(a.top));
    expect(tester.takeException(), isNull);
  });
  testWidgets('ヒントはパズルを圧迫せず、段階的に開いて保存できる', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('open-puzzle-hints')));
    await tester.pumpAndSettle();
    expect(find.text(words.first.clue), findsWidgets);
    expect(find.text('最初の文字は「さ」'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('dialog-next-hint')));
    await tester.pumpAndSettle();
    expect(find.text('最初の文字は「さ」'), findsWidgets);
    await tester.tap(find.text('とじる'));
    await tester.pumpAndSettle();
    expect(find.byType(KanaKeyboard).hitTestable(), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(Progress.decode(prefs.getString('forest_progress')).hints, 2);
    expect(tester.takeException(), isNull);
  });

  for (final height in [568.0, 640.0]) {
    for (final wordIndex in [0, 23]) {
      testWidgets(
        '320×$height・大きめ・${words[wordIndex].text.length}文字でも履歴とキーと回答が収まる',
        (tester) async {
          tester.view.physicalSize = Size(320, height);
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPadding);
          final length = words[wordIndex].text.length;
          await open(
            tester,
            progress: Progress(
              solved: wordIndex,
              largeText: true,
              reduceMotion: true,
              guesses: List.filled(30, 'あ' * length),
            ),
          );
          await typeWord(tester, words[wordIndex].text);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('kana-あ')),
            50,
            scrollable: find.descendant(
              of: find.byKey(const ValueKey('kana-table')),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();
          final area = tester.getRect(
            find.byKey(const ValueKey('history-area')),
          );
          // Scroll to the newest history while the input remains fixed.
          await tester.scrollUntilVisible(
            find.byKey(ValueKey('$wordIndex-29')),
            60,
            scrollable: find.descendant(
              of: find.byKey(const ValueKey('history-area')),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();
          final latest = tester.getRect(find.byKey(ValueKey('$wordIndex-29')));
          expect(area.height, greaterThanOrEqualTo(latest.height));
          expect(latest.top, greaterThanOrEqualTo(area.top - 1));
          expect(latest.bottom, lessThanOrEqualTo(area.bottom + 1));
          final rect = tester.getRect(answer());
          expect(rect.bottom, lessThanOrEqualTo(height - 16));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
          expect(
            tester.getSize(find.byKey(const ValueKey('kana-あ'))).width,
            greaterThanOrEqualTo(48),
          );
          expect(tester.testTextInput.isVisible, false);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('回答中の反転を保ち、履歴を残して削除と再挑戦ができる', (tester) async {
    await open(
      tester,
      progress: Progress(guesses: List.filled(30, 'あいう'), reduceMotion: false),
    );
    await typeWord(tester, 'さささ');
    await tester.tap(answer());
    await tester.pump();
    expect(find.text('ことばを見てみましょう…'), findsOneWidget);
    expect(find.byType(KanaKeyboard), findsNothing);
    await tester.pump(const Duration(milliseconds: 180));
    expect(find.text('ことばを見てみましょう…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(KanaKeyboard), findsOneWidget);
    await typeWord(tester, 'さくら');
    await tester.tap(find.byKey(const ValueKey('erase-letter')));
    await tester.pumpAndSettle();
    expect(draft(tester), 'さく');
    final prefs = await SharedPreferences.getInstance();
    expect(
      Progress.decode(prefs.getString('forest_progress')).guesses.length,
      31,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('文字サイズの標準・大きめを切り替えて保存できる', (tester) async {
    await open(tester, progress: Progress(reduceMotion: true));
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-settings')));
    await tester.pumpAndSettle();
    expect(find.text('標準'), findsOneWidget);
    await tester.tap(find.text('大きめ'));
    await tester.pumpAndSettle();
    expect(find.text('大きめ'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(Progress.decode(prefs.getString('forest_progress')).largeText, true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('色の説明を任意に開き、正解の短いお祝い後に次へ進める', (tester) async {
    await open(tester, progress: Progress(reduceMotion: false));
    await tester.tap(find.text('見かた'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('色と記号の見かた'), findsOneWidget);
    await tester.tap(find.text('とじる'));
    await tester.pump(const Duration(milliseconds: 400));
    await typeWord(tester, 'さくら');
    await tester.tap(answer());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(find.byType(SuccessPetals), findsOneWidget);
    expect(find.text('つぎの問題'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.byType(SuccessPetals), findsNothing);
    expect(find.text('つぎの問題'), findsOneWidget);
  });

  testWidgets('今日のことばから通常の問題へ戻っても途中の回答を維持する', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(
      tester,
      progress: Progress(guesses: ['あいう'], hints: 1, reduceMotion: true),
    );
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    final daily = find.text('今日のことば');
    await tester.scrollUntilVisible(daily, 150);
    await tester.pumpAndSettle();
    await tester.ensureVisible(daily);
    await tester.pumpAndSettle();
    await tester.tap(daily);
    await tester.pumpAndSettle();
    await typeWord(
      tester,
      TodayPuzzle.forDate(Progress.dayKey(DateTime.now())).text,
    );
    await tester.tap(answer());
    await tester.pumpAndSettle();
    expect(find.text('今日のことばクリア！ +30コイン'), findsOneWidget);
    expect(find.text('通常の問題へ'), findsOneWidget);
    await tester.tap(find.text('通常の問題へ'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('0-0')), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    final saved = Progress.decode(prefs.getString('forest_progress'));
    expect(saved.guesses, ['あいう']);
    expect(saved.hints, 1);
    expect(saved.today.won, true);
    expect(saved.coins, 30);
    expect(saved.todayRewards, {Progress.dayKey(DateTime.now())});
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    final cleared = find.text('本日はクリア済み');
    await tester.scrollUntilVisible(cleared, 150);
    await tester.pumpAndSettle();
    await tester.tap(cleared);
    await tester.pumpAndSettle();
    expect(cleared, findsOneWidget);
    expect(Progress.decode(prefs.getString('forest_progress')).coins, 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('3文字と4文字の大きな選択ボタンから、入力途中と再起動を保つ', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(
      tester,
      progress: Progress(mode: 3, reduceMotion: true, largeText: true),
    );
    expect(find.text('3文字であそぶ'), findsOneWidget);
    await tester.tap(find.text('3文字であそぶ'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LetterBoard>(find.byKey(const ValueKey('draft-board')))
          .length,
      3,
    );
    await typeWord(tester, 'さく');
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    await enterModePickerFromHome(tester);
    await tester.tap(find.text('4文字であそぶ'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LetterBoard>(find.byKey(const ValueKey('draft-board')))
          .length,
      4,
    );
    await typeWord(tester, 'あいうえ');
    await tester.tap(answer());
    await tester.pumpAndSettle();
    await typeWord(tester, 'たんぽぽ');
    await tester.tap(answer());
    await tester.pumpAndSettle();
    expect(find.text('せいかい！'), findsOneWidget);
    await tester.tap(find.text('つぎの問題'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    var saved = Progress.decode(prefs.getString('forest_progress'));
    expect(saved.mode, 4);
    expect(saved.word.text, 'どんぐり');
    expect(saved.modes[3]!.draft, 'さく');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    await enterModePickerFromHome(tester);
    await tester.tap(find.text('3文字であそぶ'));
    await tester.pumpAndSettle();
    expect(draft(tester), 'さく');
    await typeWord(tester, 'ら');
    await tester.tap(answer());
    await tester.pumpAndSettle();
    saved = Progress.decode(prefs.getString('forest_progress'));
    expect(saved.won, true);
    expect(saved.word.text.length, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('設定の試聴ボタンで3種類を呼び出し、効果音オフでは無効になる', (tester) async {
    final sounds = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ForestAudio.channel, (call) async {
          if (call.method == 'play') sounds.add(call.arguments as String);
          return call.method == 'play' ? true : null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ForestAudio.channel, null),
    );
    ForestAudio.resetForTesting();
    await open(tester, progress: Progress(reduceMotion: true));
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-settings')));
    await tester.pumpAndSettle();
    final preview = find.widgetWithText(OutlinedButton, '効果音を試す');
    await tester.ensureVisible(preview);
    await tester.pumpAndSettle();
    await tester.tap(preview);
    await tester.pumpAndSettle();
    for (final label in ['タップ音', '推測ミスの音', '正解音']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(sounds, containsAll(['key', 'wrong', 'win']));
    await tester.tap(find.text('とじる'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('効果音'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('効果音'));
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(preview).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  test('濁点・半濁点・小文字は可逆で、対象外の文字を変えない', () {
    for (final pair in ['かが', 'しじ', 'つづ', 'はば', 'うゔ']) {
      expect(changeKana(pair[0], KanaChange.voiced), pair[1]);
      expect(changeKana(pair[1], KanaChange.voiced), pair[0]);
    }
    expect(changeKana('は', KanaChange.halfVoiced), 'ぱ');
    expect(changeKana('ば', KanaChange.halfVoiced), 'ぱ');
    expect(changeKana('ぱ', KanaChange.voiced), 'ば');
    expect(changeKana('ぱ', KanaChange.halfVoiced), 'は');
    for (final pair in ['あぁ', 'つっ', 'やゃ', 'わゎ']) {
      expect(changeKana(pair[0], KanaChange.small), pair[1]);
      expect(changeKana(pair[1], KanaChange.small), pair[0]);
    }
    for (final change in KanaChange.values) {
      expect(changeKana('', change), '');
      expect(changeKana('ん', change), 'ん');
    }
  });
}

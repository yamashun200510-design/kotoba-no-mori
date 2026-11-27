import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotoba_no_mori/main.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/invitation.dart';
import 'app_launch.dart';

void main() {
  testWidgets('自由作問→コピー→入力→誤答→正解でも保存データと報酬を変えない', (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    String? clipboard;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String;
      }
      if (call.method == 'Clipboard.getData') return {'text': clipboard};
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final p = Progress(mode: 3, coins: 123, draft: 'さ', reduceMotion: true)
      ..draft = 'さ'
      ..welcomeSeen = true
      ..loginDate = Progress.dayKey(DateTime.now())
      ..loginDay = 1;
    SharedPreferences.setMockInitialValues({'forest_progress': p.encode()});
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final before = prefs.getString('forest_progress');
    final entry = find.text('ことばの招待状');
    expect(tester.getRect(entry).bottom, lessThan(914));
    await tester.tap(entry);
    await tester.pumpAndSettle();
    final answer = find.byKey(const ValueKey('invitation-answer'));
    await tester.enterText(answer, 'ころす');
    await tester.ensureVisible(find.byKey(const ValueKey('create-invitation')));
    await tester.tap(find.byKey(const ValueKey('create-invitation')));
    await tester.pumpAndSettle();
    expect(find.text(InvitationCode.blocked), findsOneWidget);
    await tester.enterText(answer, 'ここあ');
    final hint = find.byKey(const ValueKey('invitation-hint'));
    await tester.enterText(hint, 'ここあだよ');
    await tester.pump();
    expect(find.byKey(const ValueKey('hint-answer-warning')), findsOneWidget);
    const clue = '冬に飲みたい、あたたかいもの。';
    await tester.enterText(hint, clue);
    await tester.pump();
    expect(find.byKey(const ValueKey('hint-answer-warning')), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('create-invitation')));
    await tester.tap(find.byKey(const ValueKey('create-invitation')));
    await tester.pumpAndSettle();
    final code = tester
        .widget<SelectableText>(find.byKey(const ValueKey('invitation-code')))
        .data!;
    await tester.ensureVisible(find.byKey(const ValueKey('copy-invitation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('copy-invitation')));
    await tester.pumpAndSettle();
    expect(clipboard, code);
    expect(InvitationCode.decode(code), 'ここあ');
    await tester.ensureVisible(find.text('コードであそぶ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('コードであそぶ'));
    await tester.pumpAndSettle();
    final codeInput = find.byKey(const ValueKey('invitation-code-input'));
    await tester.enterText(codeInput, 'ABC');
    await tester.ensureVisible(find.byKey(const ValueKey('play-invitation')));
    await tester.tap(find.byKey(const ValueKey('play-invitation')));
    await tester.pumpAndSettle();
    expect(find.text(InvitationCode.invalid), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('paste-invitation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('paste-invitation')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('play-invitation')));
    await tester.tap(find.byKey(const ValueKey('play-invitation')));
    await tester.pumpAndSettle();
    expect(find.text('ユーザーが作成した問題です'), findsOneWidget);
    expect(find.text(clue), findsNothing);
    await tester.tap(find.text('ヒントを見る'));
    await tester.pumpAndSettle();
    expect(find.text(clue), findsOneWidget);
    expect(prefs.getString('forest_progress'), before);
    await tester.tap(find.text('とじる'));
    await tester.pumpAndSettle();
    expect(find.text(clue), findsNothing);
    for (final word in ['あああ', 'ここあ']) {
      for (final letter in word.split('')) {
        await tester.tap(find.byKey(ValueKey('kana-$letter')));
        await tester.pump();
      }
      await tester.tap(find.widgetWithText(FilledButton, '答える'));
      await tester.pumpAndSettle();
    }
    expect(find.text('今回は2回で正解！'), findsOneWidget);
    expect(find.text('招待状にもどる'), findsOneWidget);
    expect(prefs.getString('forest_progress'), before);
    await tester.tap(find.text('招待状にもどる'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    expect(prefs.getString('forest_progress'), before);
    expect(Progress.decode(before).draft, 'さ');
    expect(tester.takeException(), isNull);
  });
}

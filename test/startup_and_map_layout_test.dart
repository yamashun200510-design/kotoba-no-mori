import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/loading_screen.dart';
import 'package:kotoba_no_mori/stage_journey.dart';
import 'package:kotoba_no_mori/main.dart';
import 'app_launch.dart';

void main() {
  testWidgets('ロード画面にタイトルと「よみこみ中」を表示する', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForestLoadingScreen()));
    expect(find.text('ことばの森'), findsOneWidget);
    expect(find.text('よみこみ中…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('起動直後はロード画面が出て、読み込み後に消える', (tester) async {
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
    SharedPreferences.setMockInitialValues({
      'forest_progress': Progress(reduceMotion: true).encode(),
    });
    await tester.pumpWidget(const ForestApp());
    expect(find.byKey(const ValueKey('loading-screen')), findsOneWidget);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('loading-screen')), findsNothing);
    expect(find.byKey(const ValueKey('title-start')), findsOneWidget);
  });

  for (final size in const [Size(320, 640), Size(360, 780)]) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets('ステージマップの見出しが$size・文字$scale倍でも1行に収まる', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
        final progress = Progress(reduceMotion: true)
          ..loginDate = Progress.dayKey(DateTime.now())
          ..loginDay = 1;
        SharedPreferences.setMockInitialValues({
          'forest_progress': progress.encode(),
        });
        await tester.pumpWidget(const ForestApp());
        await enterPastTitle(tester);
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text('あそぶ'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));

        // Single-line labels: their height stays one line of text.
        for (final key in ['stage-progress', 'stage-star-help']) {
          final box = tester.getRect(find.byKey(ValueKey(key)));
          expect(box.height, lessThan(56), reason: key);
          expect(box.right, lessThanOrEqualTo(size.width), reason: key);
        }
        // Every stage marker stays inside the map horizontally.
        for (var id = 1; id <= forestStages.length; id++) {
          final marker = tester.getRect(find.byKey(ValueKey('stage-$id')));
          expect(marker.left, greaterThanOrEqualTo(0), reason: 'stage $id');
          expect(
            marker.right,
            lessThanOrEqualTo(size.width),
            reason: 'stage $id',
          );
        }
        // Neighbouring markers near the top no longer overlap.
        final eight = tester.getRect(find.byKey(const ValueKey('stage-8')));
        final nine = tester.getRect(find.byKey(const ValueKey('stage-9')));
        final ten = tester.getRect(find.byKey(const ValueKey('stage-10')));
        expect(eight.overlaps(nine.deflate(1)), false);
        expect(nine.overlaps(ten.deflate(1)), false);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final size in const [Size(320, 640), Size(360, 720)]) {
    for (final large in const [false, true]) {
      testWidgets('ホームのボタン名が$size・大きめ=$largeでも言葉の途中で改行・省略されない', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
        final progress = Progress(reduceMotion: true, largeText: large)
          ..loginDate = Progress.dayKey(DateTime.now())
          ..loginDay = 1;
        SharedPreferences.setMockInitialValues({
          'forest_progress': progress.encode(),
        });
        await tester.pumpWidget(const ForestApp());
        await enterPastTitle(tester);
        await tester.pump(const Duration(seconds: 1));
        const labels = [
          '今日のことば',
          'わたしの森',
          'わたしの記録',
          'あそびかた',
          'ことばの招待状',
          '今日の目標 0/3問 ・ 達成で30コイン',
        ];
        for (final label in labels) {
          final paragraph = tester
              .renderObjectList<RenderParagraph>(find.byType(RichText))
              .firstWhere(
                (p) =>
                    p.text
                        .toPlainText()
                        .replaceAll('\n', '')
                        .replaceAll('今日の目標 0/3問達成', '今日の目標 0/3問 ・ 達成') ==
                    label,
              );
          final text = paragraph.text.toPlainText();
          // Lines on screen are exactly the intended ones: no automatic
          // wrap inside a word, and nothing cut off with an ellipsis.
          expect(
            paragraph
                .getBoxesForSelection(
                  TextSelection(baseOffset: 0, extentOffset: text.length),
                )
                .map((b) => b.top.round())
                .toSet()
                .length,
            text.split('\n').length,
            reason: label,
          );
          expect(paragraph.didExceedMaxLines, false, reason: label);
          expect(text.contains('…'), false, reason: label);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final size in const [Size(320, 640), Size(360, 720)]) {
    for (final large in const [false, true]) {
      testWidgets('文字数をえらぶ画面の文が$size・大きめ=$largeでも言葉の途中で改行されない', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
        final progress = Progress(reduceMotion: true, largeText: large)
          ..loginDate = Progress.dayKey(DateTime.now())
          ..loginDay = 1;
        SharedPreferences.setMockInitialValues({
          'forest_progress': progress.encode(),
        });
        await tester.pumpWidget(const ForestApp());
        await enterPastTitle(tester);
        await tester.pump(const Duration(seconds: 1));
        final dynamic app = tester.state(find.byType(ForestApp));
        app.go('文字数をえらぶ');
        await tester.pump(const Duration(seconds: 1));
        final labels = [
          '何文字であそびますか？',
          '途中の答えは、文字数ごとに残ります。',
          '${words.where((w) => w.text.length == 3).length}問 ・ 何度でもあそべます',
        ];
        for (final label in labels) {
          final text = tester.widgetList<Text>(findLabel(label)).first;
          final paragraph = tester
              .renderObjectList<RenderParagraph>(
                find.descendant(
                  of: find.byWidget(text),
                  matching: find.byType(RichText),
                ),
              )
              .first;
          final shown = paragraph.text.toPlainText();
          expect(
            paragraph
                .getBoxesForSelection(
                  TextSelection(baseOffset: 0, extentOffset: shown.length),
                )
                .map((b) => b.top.round())
                .toSet()
                .length,
            shown.split('\n').length,
            reason: label,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}

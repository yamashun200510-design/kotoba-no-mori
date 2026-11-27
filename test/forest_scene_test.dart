import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/forest_scene.dart';

void main() {
  const artKey = ValueKey('art');
  Widget scene(
    int growth, {
    bool animate = false,
    bool reduced = false,
    Set<String> items = const {},
    int? month,
    int hour = 12,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: artKey,
            child: SizedBox(
              width: 420,
              height: 320,
              child: ForestScene(
                growth: growth,
                animate: animate,
                items: items,
                month: month,
                hour: hour,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<List<int>> capture(WidgetTester tester, {String? path}) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(artKey),
    );
    return (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = data!.buffer.asUint8List();
      if (path != null) {
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
      }
      return bytes.toList();
    }))!;
  }

  testWidgets('時間帯の境界と四季が共存し、夜も購入品を保つ', (tester) async {
    expect([4, 5, 9, 10, 15, 16, 18, 19, 23].map(timeForHour).toList(), [
      ForestTime.night,
      ForestTime.morning,
      ForestTime.morning,
      ForestTime.day,
      ForestTime.day,
      ForestTime.evening,
      ForestTime.evening,
      ForestTime.night,
      ForestTime.night,
    ]);
    final snapshots = <List<int>>[];
    for (final hour in [7, 12, 17, 22]) {
      await tester.pumpWidget(
        scene(6, month: 10, hour: hour, items: {'cherry', 'butterfly'}),
      );
      await tester.pumpAndSettle();
      final bytes = await capture(
        tester,
        path: 'build/verification/forest-hour-$hour.png',
      );
      for (final old in snapshots) {
        expect(bytes, isNot(equals(old)));
      }
      snapshots.add(bytes);
      expect(tester.widget<ForestScene>(find.byType(ForestScene)).items, {
        'cherry',
        'butterfly',
      });
    }
  });

  testWidgets('森のおともだちは進行に応じて表示され、タップで吹き出す', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              height: 320,
              child: ForestScene(
                growth: 5,
                friends: {'rabbit', 'squirrel'},
                editable: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.byKey(const ValueKey('forest-friend-squirrel')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('forest-friend-squirrel')));
    await tester.pump();
    expect(find.text('木の実を見つけたよ！'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // disposes the bubble timer
  });

  testWidgets('幹の根元を固定し、枝葉・購入花・草がそれぞれ動く', (tester) async {
    await tester.pumpWidget(
      scene(6, animate: true, month: 7, items: {'tulip', 'sunflower'}),
    );
    await tester.pump(const Duration(seconds: 1));
    Future<Map<String, List<int>>> regions() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(artKey),
      );
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = (await image.toByteData())!.buffer.asUint8List();
        final result = <String, List<int>>{};
        for (final entry in <String, Rect>{
          'root': const Rect.fromLTWH(158, 237, 1, 1),
          'canopy': const Rect.fromLTWH(100, 90, 100, 90),
          'tulip': const Rect.fromLTWH(95, 250, 70, 60),
          'sunflower': const Rect.fromLTWH(225, 215, 65, 90),
          'grass': const Rect.fromLTWH(0, 270, 30, 45),
        }.entries) {
          result[entry.key] = [
            for (var y = entry.value.top.toInt(); y < entry.value.bottom; y++)
              ...data.sublist(
                (y * image.width + entry.value.left.toInt()) * 4,
                (y * image.width + entry.value.right.toInt()) * 4,
              ),
          ];
        }
        image.dispose();
        return result;
      }))!;
    }

    final before = await regions();
    await tester.pump(const Duration(milliseconds: 1400));
    final after = await regions();
    expect(after['root'], before['root']);
    for (final part in ['canopy', 'tulip', 'sunflower', 'grass']) {
      expect(after[part], isNot(equals(before[part])), reason: part);
    }
    await capture(tester, path: 'build/verification/forest-wind.png');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('画面外の森は停止し、戻すと再開する', (tester) async {
    final scroll = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: scroll,
            children: const [
              ForestScene(growth: 6, hour: 12),
              SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    scroll.jumpTo(1200);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    scroll.jumpTo(0);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    scroll.dispose();
  });

  testWidgets('四季で描画が変わり、購入品を保つ', (tester) async {
    final images = <List<int>>[];
    for (final month in [4, 7, 10, 1]) {
      await tester.pumpWidget(
        scene(6, month: month, items: {'cherry', 'tulip'}),
      );
      await tester.pumpAndSettle();
      final bytes = await capture(
        tester,
        path: 'build/verification/season-$month.png',
      );
      for (final previous in images) {
        expect(bytes, isNot(equals(previous)));
      }
      images.add(bytes);
      expect(tester.widget<ForestScene>(find.byType(ForestScene)).items, {
        'cherry',
        'tulip',
      });
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('成長で実際の景色が変わり、各段階を描画できる', (tester) async {
    List<int>? previous;
    for (final stage in [0, 2, 4, 8]) {
      await tester.pumpWidget(scene(stage));
      await tester.pumpAndSettle();
      final bytes = await capture(
        tester,
        path: 'build/verification/storybook-growth-$stage.png',
      );
      if (previous != null) expect(bytes, isNot(equals(previous)));
      previous = bytes;
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('購入品は成長とは独立して描画され、追加後も動きを減らせる', (tester) async {
    await tester.pumpWidget(scene(4));
    await tester.pumpAndSettle();
    final before = await capture(tester);
    await tester.pumpWidget(
      scene(
        4,
        animate: true,
        items: {'tulip', 'mushroom', 'sunflower', 'butterfly', 'cherry'},
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final after = await capture(
      tester,
      path: 'build/verification/forest-shop.png',
    );
    expect(after, isNot(equals(before)));
    await tester.pumpWidget(
      scene(
        4,
        animate: true,
        reduced: true,
        items: {'tulip', 'mushroom', 'sunflower', 'butterfly', 'cherry'},
      ),
    );
    await tester.pumpAndSettle();
    final still = await capture(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(await capture(tester), equals(still));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('森は動き、端末の動きを減らす設定で描画更新が止まる', (tester) async {
    Future<List<int>> skyPixel() async => (await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(artKey),
      );
      final image = await boundary.toImage();
      final data = await image.toByteData();
      final offset = (10 * image.width + 210) * 4;
      final pixel = data!.buffer.asUint8List().sublist(offset, offset + 4);
      image.dispose();
      return pixel;
    }))!;
    await tester.pumpWidget(scene(8, animate: true));
    await tester.pump();
    final before = await capture(tester);
    final skyBefore = await skyPixel();
    await tester.pump(const Duration(milliseconds: 600));
    expect(await capture(tester), isNot(equals(before)));
    expect(await skyPixel(), equals(skyBefore));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(scene(8, animate: true, reduced: true));
    await tester.pumpAndSettle();
    final still = await capture(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(await capture(tester), equals(still));
    expect(tester.binding.transientCallbackCount, 0);
  });
}

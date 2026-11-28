import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/stage_journey.dart';
import 'package:kotoba_no_mori/stage_map.dart';

void main() {
  testWidgets('挑戦中のステージが見える間は地図を動かさず上端ステージを隠さない', (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    final journey = StageJourney()..stars.addAll({1: 3, 2: 3});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TickerMode(
            enabled: false,
            child: ForestStageMap(
              journey: journey,
              onSelect: (_) {},
              onNormalModes: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final viewport = tester.getRect(
      find.byKey(const ValueKey('stage-map-scroll')),
    );
    for (final id in [3, 10]) {
      final marker = tester.getRect(find.byKey(ValueKey('stage-$id')));
      expect(marker.top, greaterThanOrEqualTo(viewport.top));
      expect(marker.bottom, lessThanOrEqualTo(viewport.bottom));
    }
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 640), const Size(411, 914)]) {
    testWidgets('背景と操作を分離し、現在地とロックを維持 $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      final journey = StageJourney();
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TickerMode(
              enabled: false,
              child: ForestStageMap(
                journey: journey,
                onSelect: (id) => selected = id,
                onNormalModes: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const ValueKey('stage-2')))
            .onPressed,
        isNull,
      );
      final stage = find.byKey(const ValueKey('stage-1'));
      expect(tester.getRect(stage).bottom, lessThan(size.height));
      await tester.tap(stage);
      await tester.pumpAndSettle();
      expect(selected, 1);
      expect(journey.stars, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('獲得した星はステージボタンの上に見え、未獲得時は表示しない', (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    final journey = StageJourney()..stars[1] = 3;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TickerMode(
            enabled: false,
            child: ForestStageMap(
              journey: journey,
              onSelect: (_) {},
              onNormalModes: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('星3 / 3'), findsOneWidget);
    expect(find.bySemanticsLabel('星0 / 3'), findsNothing);
    final stars = tester.getRect(find.byType(StageStars));
    final marker = tester.getRect(find.byKey(const ValueKey('stage-1')));
    expect(stars.bottom, lessThanOrEqualTo(marker.top));
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(320, 640), Size(411, 914)]) {
    testWidgets('クリア済みの星はすべてのステージの丸より手前に描かれ、隠れない $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      // Stages 1-9 cleared on the tightly spaced original map of area 1.
      final journey = StageJourney()
        ..stars.addAll({for (var id = 1; id <= 9; id++) id: id.isEven ? 2 : 3});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TickerMode(
              enabled: false,
              child: ForestStageMap(
                journey: journey,
                onSelect: (_) {},
                onNormalModes: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StageStars), findsNWidgets(9));
      // A Stack paints its children in order: every star row must come after
      // every stage button, so no button (e.g. the next stage's) covers it.
      final order = find
          .byWidgetPredicate(
            (w) =>
                w is StageStars ||
                (w is ElevatedButton &&
                    w.key is ValueKey<String> &&
                    (w.key! as ValueKey<String>).value.startsWith('stage-')),
          )
          .evaluate()
          .map((e) => e.widget is StageStars)
          .toList();
      expect(order.lastIndexOf(false), lessThan(order.indexOf(true)));
      // Each star row still sits just above a cleared stage's button.
      final markers = [
        for (var id = 1; id <= 9; id++)
          tester.getRect(find.byKey(ValueKey('stage-$id'))),
      ];
      for (final element in find.byType(StageStars).evaluate()) {
        final stars = tester.getRect(find.byWidget(element.widget));
        expect(
          markers.any(
            (m) =>
                (m.center.dx - stars.center.dx).abs() < m.width &&
                m.top - stars.bottom >= -4 &&
                m.top - stars.bottom < 12,
          ),
          isTrue,
          reason: '$stars',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}

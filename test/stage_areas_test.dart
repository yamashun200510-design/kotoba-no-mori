import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/stage_areas.dart';
import 'package:kotoba_no_mori/stage_journey.dart';
import 'package:kotoba_no_mori/stage_layout.dart';
import 'package:kotoba_no_mori/stage_map.dart';

void main() {
  test('1,000ステージ・25エリア×40。答えは重複なく、全部が単語データにある', () {
    expect(forestStages.length, 1000);
    expect(maxStageId, forestStages.length);
    expect(forestAreas.length * stagesPerArea, forestStages.length);
    for (var i = 0; i < forestStages.length; i++) {
      expect(forestStages[i].id, i + 1);
    }
    final answers = forestStages.map((s) => s.answer).toList();
    expect(answers.toSet().length, answers.length);
    final catalogue = words.map((w) => w.text).toSet();
    for (final answer in answers) {
      expect(catalogue, contains(answer), reason: answer);
      expect(answer.length, inInclusiveRange(3, 5), reason: answer);
    }
    // Stages 1-10 keep their original answers (saved sessions stay valid).
    expect(answers.take(10), [
      'さくら',
      'うさぎ',
      'すみれ',
      'たんぽぽ',
      'きつね',
      'どんぐり',
      'もみじ',
      'ひまわり',
      'いちご',
      'あじさい',
    ]);
    expect(forestStages.first.area, '花咲く小道');
    expect(forestStages[40].area, forestAreas[1].name);
    expect(forestStages.last.area, forestAreas.last.name);
    expect(
      forestAreas.map((a) => a.road).toSet(),
      RoadStyle.values.toSet(),
      reason: '道の形は6種類すべて使う',
    );
    for (var i = 1; i < forestAreas.length; i++) {
      expect(
        forestAreas[i].road,
        isNot(forestAreas[i - 1].road),
        reason: '隣り合うエリアは道の形を変える',
      );
    }
    expect(
      forestAreas.map((a) => a.theme).toSet(),
      AreaTheme.values.toSet(),
      reason: '8つの風景テーマをすべて旅する',
    );
  });

  for (final width in const [320.0, 360.0, 411.0]) {
    test('幅$widthで全エリアの40ステージが道に沿って等間隔に並び、重ならない', () {
      for (final area in forestAreas) {
        final layout = layoutArea(area, width);
        final ids = [
          for (var id = area.firstStage; id <= area.lastStage; id++) id,
        ];
        expect(layout.nodes.keys.toList()..sort(), ids, reason: area.name);
        final scale = (width / 400).clamp(.82, 1.0);
        for (final id in ids) {
          final p = layout.nodes[id]!;
          expect(
            p.dx,
            inInclusiveRange(30, width - 30),
            reason: '${area.name} $id',
          );
          expect(
            p.dy,
            inInclusiveRange(30, layout.height - 30),
            reason: '${area.name} $id',
          );
          if (id > area.firstStage) {
            final gap = (p - layout.nodes[id - 1]!).distance;
            expect(gap, greaterThan(48 * scale), reason: '${area.name} $id');
          }
        }
        if (layout.trail.isNotEmpty) {
          // The last stage ends the road; painted areas also start on it.
          expect(
            (layout.nodes[area.lastStage]! - layout.trail.last).distance,
            lessThan(.01),
          );
          if (area.number != 1) {
            expect(
              (layout.nodes[area.firstStage]! - layout.trail.first).distance,
              lessThan(.01),
            );
          }
          // Equal steps along the road: the straight gap between neighbours
          // equals the step on straight stretches and is shorter only where
          // the road turns a corner between them.
          var length = 0.0;
          for (var i = 1; i < layout.trail.length; i++) {
            length += (layout.trail[i] - layout.trail[i - 1]).distance;
          }
          final from = area.number == 1
              ? area.firstStage + 10
              : area.firstStage + 1;
          final steps = area.number == 1
              ? stagesPerArea - 10
              : stagesPerArea - 1;
          final step = length / steps;
          for (var id = from; id <= area.lastStage; id++) {
            final gap = (layout.nodes[id]! - layout.nodes[id - 1]!).distance;
            expect(
              gap,
              lessThanOrEqualTo(step * 1.01),
              reason: '${area.name} $id',
            );
            expect(
              gap,
              greaterThanOrEqualTo(step * .6),
              reason: '${area.name} $id',
            );
          }
        }
      }
    });
  }

  test('エリア1のステージ1〜10は元のマップの確認済みの位置のまま', () {
    const width = 360.0;
    final layout = layoutArea(forestAreas.first, width);
    final legacy = width * legacyMapAspect;
    final top = layout.height - legacy;
    expect(layout.legacyHeight, legacy);
    for (var i = 0; i < 10; i++) {
      expect(
        layout.nodes[i + 1],
        Offset(legacyAnchors[i].dx * width, top + legacyAnchors[i].dy * legacy),
      );
    }
    // The painted road starts at stage 10 and climbs from there.
    expect(layout.trail.first, layout.nodes[10]);
  });

  test('旧10ステージの保存データをそのまま読み、次のエリアは40クリア後に開く', () {
    final old = jsonEncode({
      'version': 1,
      'stars': {for (var id = 1; id <= 10; id++) '$id': id.isEven ? 3 : 2},
      'sessions': {},
    });
    final journey = StageJourney.decode(old);
    for (var id = 1; id <= 10; id++) {
      expect(journey.stars[id], id.isEven ? 3 : 2);
    }
    expect(journey.frontier, 11);
    expect(journey.unlocked(11), isTrue);
    expect(journey.unlocked(41), isFalse);
    for (var id = 11; id <= 40; id++) {
      journey.stars[id] = 1;
    }
    expect(journey.unlocked(41), isTrue);
    expect(areaOfStage(journey.frontier).number, 2);
    final again = StageJourney.decode(journey.encode());
    expect(again.cleared, 40);
    expect(again.frontier, 41);
  });

  test('後半のステージでも初回クリアのコインが付く', () {
    final progress = Progress();
    final reward = progress.claimStageClearReward(
      500,
      DateTime(2026, 11, 28),
      wasPreviouslyCleared: false,
    );
    expect(reward, 20);
    expect(progress.coins, 20);
  });

  testWidgets('エリアを切り替えられ、未解放のエリアには進めない', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    final journey = StageJourney();
    Future<void> show() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TickerMode(
              enabled: false,
              child: ForestStageMap(
                key: UniqueKey(),
                journey: journey,
                onSelect: (_) {},
                onNormalModes: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show();
    expect(find.text('花咲く小道'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('area-next')))
          .onPressed,
      isNull,
    );
    expect(find.byKey(const ValueKey('stage-41')), findsNothing);

    for (var id = 1; id <= 40; id++) {
      journey.stars[id] = 3;
    }
    await show();
    // The current stage (41) lives in area 2, which opens automatically.
    expect(find.text(forestAreas[1].name), findsOneWidget);
    final stage41 = find.byKey(const ValueKey('stage-41'));
    expect(stage41, findsOneWidget);
    final viewport = tester.getRect(
      find.byKey(const ValueKey('stage-map-scroll')),
    );
    expect(
      tester.getRect(stage41).center.dy,
      inInclusiveRange(viewport.top, viewport.bottom),
    );
    expect(tester.widget<ElevatedButton>(stage41).onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('area-previous')));
    await tester.pumpAndSettle();
    expect(find.text('花咲く小道'), findsOneWidget);
    expect(find.byKey(const ValueKey('stage-area-complete')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

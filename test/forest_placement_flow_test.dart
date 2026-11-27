import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotoba_no_mori/coin_badge.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/main.dart';
import 'package:kotoba_no_mori/stage_journey.dart';

import 'app_launch.dart';

void main() {
  test('売却は購入価格の半額を加算し、配置と所持品を削除する', () {
    final progress = Progress(
      coins: 10,
      ownedItems: {'sunflower'},
      itemPositions: {
        'sunflower': [.5, .6],
      },
    );
    expect(progress.sellForestItem('sunflower'), 40);
    expect(progress.coins, 50);
    expect(progress.ownedItems, isEmpty);
    expect(progress.itemPositions, isEmpty);
    expect(progress.sellForestItem('sunflower'), 0);
    expect(progress.coins, 50);
  });

  testWidgets('森の風景から全画面を開き、家具操作と戻る操作ができる', (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
    final initial = Progress(
      welcomeSeen: true,
      reduceMotion: true,
      ownedItems: {'tulip'},
      itemPositions: {
        'tulip': [.5, .65],
      },
    );
    SharedPreferences.setMockInitialValues({
      'forest_progress': initial.encode(),
    });
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('わたしの森'));
    await tester.pumpAndSettle();

    final preview = find.byKey(const ValueKey('open-forest-fullscreen'));
    await tester.tap(find.byKey(const ValueKey('placed-forest-item-tulip')));
    await tester.pumpAndSettle();
    expect(find.text('移動する'), findsOneWidget);
    expect(find.text('しまう'), findsOneWidget);
    expect(find.text('売却する'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('forest-fullscreen-viewer')),
      findsNothing,
    );
    await tester.tapAt(const Offset(8, 120));
    await tester.pumpAndSettle();

    await tester.tapAt(tester.getTopLeft(preview) + const Offset(28, 28));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('forest-fullscreen-viewer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('my-forest-scene-fullscreen')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('my-forest-storage')), findsNothing);
    expect(find.byKey(const ValueKey('forest-shop-house')), findsNothing);

    final viewerFinder = find.byKey(const ValueKey('forest-fullscreen-viewer'));
    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    final initialTransform = Matrix4.copy(
      viewer.transformationController!.value,
    );
    final gestureCenter = tester.getRect(viewerFinder).center;
    final firstFinger = await tester.startGesture(
      gestureCenter - const Offset(35, 0),
      pointer: 11,
    );
    final secondFinger = await tester.startGesture(
      gestureCenter + const Offset(35, 0),
      pointer: 12,
    );
    await tester.pump();
    await firstFinger.moveTo(gestureCenter - const Offset(90, 0));
    await secondFinger.moveTo(gestureCenter + const Offset(90, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await firstFinger.up();
    await secondFinger.up();
    await tester.pumpAndSettle();
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );
    viewer.transformationController!.value = initialTransform;
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('placed-forest-item-tulip')));
    await tester.pumpAndSettle();
    expect(find.text('移動する'), findsOneWidget);
    await tester.tap(find.text('移動する'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('confirm-forest-move')), findsOneWidget);
    expect(
      tester
          .widget<InteractiveViewer>(
            find.byKey(const ValueKey('forest-fullscreen-viewer')),
          )
          .panEnabled,
      isFalse,
    );

    await tester.tap(find.byKey(const ValueKey('close-forest-fullscreen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('my-forest-scene')), findsOneWidget);
    expect(find.byKey(const ValueKey('my-forest-storage')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('森の飾りの大きさ・反転・回転・色を変更して保存し直せる', (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
    SharedPreferences.setMockInitialValues({
      'forest_progress': Progress(
        welcomeSeen: true,
        reduceMotion: true,
        ownedItems: {'tulip'},
        itemPositions: {
          'tulip': [.5, .65],
        },
      ).encode(),
    });
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('わたしの森'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('placed-forest-item-tulip')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('大きさ・向きを変える'));
    await tester.pumpAndSettle();

    expect(find.text('大きさ　100%'), findsOneWidget);
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('forest-decoration-scale')),
    );
    slider.onChanged!(1.5);
    await tester.pump();
    await tester.tap(find.text('左右反転'));
    await tester.tap(find.text('回転 0°'));
    await tester.tap(find.text('花もも'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('この飾りにする'));
    await tester.pumpAndSettle();

    var saved = Progress.decode(
      (await SharedPreferences.getInstance()).getString('forest_progress'),
    );
    var style = saved
        .forestAreaProgress(firstForestAreaId)
        .itemAppearances['tulip']!;
    expect(style.scale, 1.5);
    expect(style.flipped, isTrue);
    expect(style.rotationSteps, 1);
    expect(style.tint, 0xFFE8759C);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('わたしの森'));
    await tester.pumpAndSettle();
    saved = Progress.decode(
      (await SharedPreferences.getInstance()).getString('forest_progress'),
    );
    style = saved
        .forestAreaProgress(firstForestAreaId)
        .itemAppearances['tulip']!;
    expect(style.scale, 1.5);
    expect(style.flipped, isTrue);
    expect(style.rotationSteps, 1);
    expect(style.tint, 0xFFE8759C);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ステージ開始画面を約2秒表示してから問題へ進む', (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
    final initial = Progress(welcomeSeen: true, reduceMotion: true);
    SharedPreferences.setMockInitialValues({
      'forest_progress': initial.encode(),
      StageJourney.storageKey: StageJourney().encode(),
    });
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-play-signpost')));
    await tester.pump(const Duration(milliseconds: 180));
    final stage = find.byKey(const ValueKey('stage-1'));
    await tester.ensureVisible(stage);
    await tester.tap(stage);
    await tester.pump();
    expect(find.text('ステージ 1'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.text('ステージ 1'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('stage-map-scroll')), findsNothing);
    expect(find.byKey(const ValueKey('draft-board')), findsOneWidget);
    expect(find.text('ステージ 1'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump();
    expect(find.text('ステージ 1'), findsNothing);
    expect(find.text('パズル'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('置き場から森へ配置し、移動と収納を保存して再起動後に復元する', (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));

    final initial = Progress(welcomeSeen: true, reduceMotion: true, coins: 80);
    SharedPreferences.setMockInitialValues({
      'forest_progress': initial.encode(),
    });
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('わたしの森'));
    await tester.pumpAndSettle();

    final shopHouse = find.byKey(const ValueKey('forest-shop-house'));
    await tester.ensureVisible(shopHouse);
    await tester.tap(shopHouse);
    await tester.pumpAndSettle();
    final buy = find.descendant(
      of: find.byKey(const ValueKey('shop-tulip')),
      matching: find.widgetWithText(FilledButton, '森に迎える'),
    );
    await tester.ensureVisible(buy);
    await tester.tap(buy);
    await tester.pumpAndSettle();
    await tester.tap(find.text('購入する'));
    await tester.pumpAndSettle();
    expect(tester.widget<CoinBadge>(find.byType(CoinBadge)).coins, 50);
    await tester.tap(find.byKey(const ValueKey('previous-page')));
    await tester.pumpAndSettle();

    final stored = find.byKey(const ValueKey('forest-storage-item-tulip'));
    final scene = find.byKey(const ValueKey('my-forest-scene'));
    expect(stored, findsOneWidget);
    expect(scene, findsOneWidget);

    Future<void> longDrag(Finder source, Offset destination) async {
      final gesture = await tester.startGesture(tester.getCenter(source));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(destination);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await longDrag(stored, tester.getCenter(scene));
    var saved = Progress.decode(
      (await SharedPreferences.getInstance()).getString('forest_progress'),
    );
    expect(saved.itemPositions['tulip'], isNotNull);
    expect(
      find.byKey(const ValueKey('forest-storage-item-tulip')),
      findsNothing,
    );

    var plant = find.byKey(const ValueKey('placed-forest-item-tulip'));
    final beforeMove = List<double>.from(saved.itemPositions['tulip']!);
    final movedTo = tester.getCenter(scene) + const Offset(75, -45);
    await tester.tap(plant);
    await tester.pumpAndSettle();
    await tester.tap(find.text('移動する'));
    await tester.pumpAndSettle();
    await longDrag(plant, movedTo);
    saved = Progress.decode(
      (await SharedPreferences.getInstance()).getString('forest_progress'),
    );
    expect(saved.itemPositions['tulip'], beforeMove);
    await tester.tap(find.byKey(const ValueKey('confirm-forest-move')));
    await tester.pumpAndSettle();
    saved = Progress.decode(
      (await SharedPreferences.getInstance()).getString('forest_progress'),
    );
    final moved = List<double>.from(saved.itemPositions['tulip']!);
    expect(moved[0], greaterThan(.5));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const ForestApp());
    await enterPastTitle(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('わたしの森'));
    await tester.pumpAndSettle();
    saved = Progress.decode(
      (await SharedPreferences.getInstance()).getString('forest_progress'),
    );
    expect(saved.coins, 50);
    expect(saved.ownedItems, {'tulip'});
    expect(saved.itemPositions['tulip'], moved);

    plant = find.byKey(const ValueKey('placed-forest-item-tulip'));
    await tester.tap(plant);
    await tester.pumpAndSettle();
    await tester.tap(find.text('しまう'));
    await tester.pumpAndSettle();
    saved = Progress.decode(
      (await SharedPreferences.getInstance()).getString('forest_progress'),
    );
    expect(saved.itemPositions, isEmpty);
    expect(
      find.byKey(const ValueKey('forest-storage-item-tulip')),
      findsOneWidget,
    );
    expect(saved.ownedItems, {'tulip'});
    expect(tester.takeException(), isNull);

    await longDrag(
      find.byKey(const ValueKey('forest-storage-item-tulip')),
      tester.getCenter(scene),
    );
    plant = find.byKey(const ValueKey('placed-forest-item-tulip'));
    await tester.tap(plant);
    await tester.pumpAndSettle();
    await tester.tap(find.text('売却する'));
    await tester.pumpAndSettle();
    expect(find.textContaining('15コイン'), findsOneWidget);
    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();
    expect(
      Progress.decode(
        (await SharedPreferences.getInstance()).getString('forest_progress'),
      ).ownedItems,
      {'tulip'},
    );

    await tester.tap(plant);
    await tester.pumpAndSettle();
    await tester.tap(find.text('売却する'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('売却する').last);
    await tester.pumpAndSettle();
    saved = Progress.decode(
      (await SharedPreferences.getInstance()).getString('forest_progress'),
    );
    expect(saved.coins, 65);
    expect(saved.ownedItems, isEmpty);
    expect(saved.itemPositions, isEmpty);
  });
}

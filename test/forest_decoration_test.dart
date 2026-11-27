import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/forest_scene.dart';

void main() {
  testWidgets('配置済みの飾りを長押しドラッグすると新しい位置を通知する', (tester) async {
    String? movedItem;
    double? movedX;
    double? movedY;
    final positions = <String, List<double>>{
      'tulip': [.25, .65],
    };
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Center(
              child: SizedBox(
                width: 420,
                height: 320,
                child: ForestScene(
                  animate: false,
                  editable: true,
                  movingItem: 'tulip',
                  items: const {'tulip'},
                  itemPositions: {
                    for (final entry in positions.entries)
                      entry.key: List.of(entry.value),
                  },
                  onItemMoved: (item, x, y) {
                    movedItem = item;
                    movedX = x;
                    movedY = y;
                    setState(() => positions[item] = [x, y]);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final plant = find.byKey(const ValueKey('placed-forest-item-tulip'));
    expect(plant, findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(plant));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(const Offset(450, 400));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(movedItem, 'tulip');
    expect(movedX, greaterThan(.25));
    expect(movedY, greaterThan(.65));
    final scale = tester.widget<ScaleTransition>(
      find.byType(ScaleTransition).first,
    );
    expect(scale.scale.value, lessThan(1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(scale.scale.value, closeTo(1, .01));
  });
}

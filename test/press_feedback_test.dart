import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/press_feedback.dart';

void main() {
  testWidgets('短い押下でも操作を待たせず、軽減設定では沈まない', (tester) async {
    var taps = 0;
    for (final quiet in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: quiet),
            child: Scaffold(
              body: Center(
                child: PressFeedback(
                  child: FilledButton(
                    onPressed: () => taps++,
                    child: const Text('あそぶ'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('あそぶ')),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, quiet ? 1 : .985);
      await gesture.up();
      await tester.pump();
      expect(taps, quiet ? 2 : 1);
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    }
  });
}

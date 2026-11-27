import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/letter_board.dart';

void main() {
  testWidgets('input updates immediately and settles without overflow', (
    tester,
  ) async {
    Widget board(String text) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 280,
          child: LetterBoard(text: text, length: 4, active: true),
        ),
      ),
    );
    await tester.pumpWidget(board(''));
    await tester.pumpWidget(board('ぽ'));
    expect(find.text('ぽ'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(board(''));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('ぽ'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final reduced in [false, true]) {
    testWidgets('reveal completes once, reduced motion $reduced', (
      tester,
    ) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Scaffold(
              body: LetterBoard(
                text: 'さくら',
                length: 3,
                marks: const [Match.exact, Match.exact, Match.exact],
                reveal: true,
                onRevealComplete: () => completed++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(completed, 1);
      expect(find.text('◎'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('success tiles glow in a short left-to-right wave', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LetterBoard(
            text: 'さくら',
            length: 3,
            marks: [Match.exact, Match.exact, Match.exact],
            reveal: true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));

    final first = tester.widget<Container>(
      find.byKey(const ValueKey('answer-cell-0')),
    );
    final last = tester.widget<Container>(
      find.byKey(const ValueKey('answer-cell-2')),
    );
    final firstDecoration = first.decoration! as BoxDecoration;
    final lastDecoration = last.decoration! as BoxDecoration;
    expect(firstDecoration.boxShadow, isNotEmpty);
    expect(lastDecoration.boxShadow, isNull);
    expect(tester.takeException(), isNull);
  });
}

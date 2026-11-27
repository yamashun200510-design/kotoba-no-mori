import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/main.dart';

/// Puzzle tests keep their normal-mode fixtures; home play now opens the map.
Future<void> enterNormalPuzzle(WidgetTester tester) async {
  final dynamic app = tester.state(find.byType(ForestApp));
  app.startNormal();
  await tester.pumpAndSettle();
}

/// Existing feature tests enter home through the real startup flow.
Future<void> enterPastTitle(WidgetTester tester) async {
  final start = find.byKey(const ValueKey('title-start'));
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (start.evaluate().isNotEmpty &&
        tester.widget<FilledButton>(start).onPressed != null) {
      break;
    }
  }
  if (start.evaluate().isNotEmpty) {
    await tester.ensureVisible(start);
    await tester.tap(start);
    // Allow the full petal wipe (~2.2s) and the title→home fade to complete.
    for (var i = 0; i < 64; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
  }
  final welcome = find.byKey(const ValueKey('welcome-start'));
  if (welcome.evaluate().isNotEmpty) {
    await tester.ensureVisible(welcome);
    await tester.tap(welcome);
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
  }
}

/// Normal puzzle modes are now reached from the home play button via the map.
Future<void> enterModePickerFromHome(WidgetTester tester) async {
  await tester.tap(find.text('あそぶ'));
  // The map intentionally has an endless, low-motion ambience loop, so
  // pumpAndSettle can never finish while it is visible.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.tap(find.text('3文字・4文字をえらぶ'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

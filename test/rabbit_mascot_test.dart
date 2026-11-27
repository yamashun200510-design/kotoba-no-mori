import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/rabbit_mascot.dart';

void main() {
  const art = ValueKey('rabbit-art');
  Widget mascot({
    RabbitMood mood = RabbitMood.idle,
    bool idle = false,
    bool quiet = false,
    int event = 0,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: quiet),
      child: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: art,
            child: ColoredBox(
              color: const Color(0xFFEDF1E1),
              child: RabbitMascot(
                width: 224,
                height: 332,
                mood: mood,
                event: event,
                animateIdle: idle,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Future<List<int>> capture(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(art),
    );
    return (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final data = bytes!.buffer.asUint8List();
      final file = File('build/verification/rabbit-$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data);
      return data.toList();
    }))!;
  }

  testWidgets('まばたき・呼吸・耳の待機動作とタップで描画が変化し、軽減設定で止まる', (tester) async {
    await tester.pumpWidget(mascot(idle: true));
    final initial = await capture(tester, 'idle');
    await tester.pump(const Duration(milliseconds: 2600));
    expect(await capture(tester, 'blink'), isNot(equals(initial)));
    await tester.pump(const Duration(milliseconds: 2750));
    final twitch = await capture(tester, 'ear');
    expect(twitch, isNot(equals(initial)));
    await tester.tap(find.byType(RabbitMascot));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(await capture(tester, 'greeting'), isNot(equals(twitch)));
    await tester.pumpWidget(mascot(idle: true, quiet: true));
    await tester.pumpAndSettle();
    final still = await capture(tester, 'reduced');
    await tester.pump(const Duration(seconds: 5));
    expect(await capture(tester, 'reduced-later'), equals(still));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('喜び・お辞儀・プレゼントを切り替え、同じ状態も再実行できる', (tester) async {
    List<int>? previous;
    for (final mood in [
      RabbitMood.idle,
      RabbitMood.happy,
      RabbitMood.bow,
      RabbitMood.present,
    ]) {
      await tester.pumpWidget(mascot(mood: mood));
      await tester.pump(const Duration(milliseconds: 650));
      final bytes = await capture(tester, mood.name);
      if (previous != null) expect(bytes, isNot(equals(previous)));
      previous = bytes;
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    await tester.pumpWidget(mascot(mood: RabbitMood.present, event: 1));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });
}

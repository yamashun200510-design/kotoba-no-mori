import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Original vector launcher artwork, not a widget screenshot. Rabbit contours and
// palette follow lib/rabbit_mascot.dart. The bundled Zen Maru font is SIL OFL.
const forest = Color(0xFF244F3E);

void drawIcon(Canvas c, {bool foreground = false}) {
  final p = Paint()..isAntiAlias = true;
  void fill(Path path, Color color) => c.drawPath(
    path,
    p
      ..shader = null
      ..style = PaintingStyle.fill
      ..color = color,
  );
  void line(Path path, Color color, double width) => c.drawPath(
    path,
    p
      ..shader = null
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  void oval(Rect rect, Color color) => c.drawOval(
    rect,
    p
      ..shader = null
      ..style = PaintingStyle.fill
      ..color = color,
  );
  void fur(Path path, Rect bounds) {
    c.drawPath(
      path,
      p
        ..style = PaintingStyle.fill
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFDF6), Color(0xFFF2E4CB)],
        ).createShader(bounds),
    );
    line(path, const Color(0xFFB7A88B), 1.15);
  }

  if (!foreground) c.drawColor(forest, BlendMode.src);
  c.save();
  if (foreground) {
    // Android's 108dp layer is displayed through a 72dp mask. This maps the
    // legacy composition into its central 66dp safe circle, leaving overscan.
    c.translate(64, 64);
    c.scale(.60);
    c.translate(-64, -64);
  }
  // Two quiet leaves, behind the character rather than around the lettering.
  fill(
    Path()
      ..moveTo(33, 105)
      ..cubicTo(16, 101, 16, 88, 18, 84)
      ..cubicTo(30, 85, 37, 96, 33, 105)
      ..close(),
    const Color(0xFF518366),
  );
  fill(
    Path()
      ..moveTo(96, 105)
      ..cubicTo(109, 100, 112, 90, 109, 86)
      ..cubicTo(98, 88, 92, 97, 96, 105)
      ..close(),
    const Color(0xFF6C936A),
  );

  final body = Path()
    ..moveTo(34, 119)
    ..cubicTo(20, 109, 27, 86, 44, 78)
    ..cubicTo(55, 72, 74, 73, 86, 81)
    ..cubicTo(101, 90, 103, 111, 94, 119)
    ..quadraticBezierTo(64, 126, 34, 119)
    ..close();
  fur(body, const Rect.fromLTWH(26, 75, 76, 48));

  void ear(double x, double y, double angle, double length) {
    c.save();
    c.translate(x, y);
    c.rotate(angle);
    final shape = Path()
      ..moveTo(-8, 1)
      ..cubicTo(-16, -length * .42, -11, -length, -2, -length)
      ..cubicTo(8, -length - 3, 15, -length * .44, 8, 1)
      ..quadraticBezierTo(0, 7, -8, 1)
      ..close();
    fur(shape, Rect.fromLTWH(-15, -length, 30, length));
    fill(
      Path()
        ..moveTo(-3, -6)
        ..cubicTo(-8, -length * .45, -6, -length + 8, -1, -length + 7)
        ..cubicTo(5, -length + 8, 9, -length * .45, 3, -6)
        ..close(),
      const Color(0xFFEAC0BA),
    );
    line(
      Path()
        ..moveTo(-1, -10)
        ..quadraticBezierTo(-3, -length * .5, -2, -length + 13),
      const Color(0xFFF6D7CC),
      2,
    );
    c.restore();
  }

  c.save();
  c.translate(64, 63);
  ear(-17, -15, -.13, 39);
  ear(15, -17, .12, 40);
  final head = Path()
    ..moveTo(-30, 7)
    ..cubicTo(-37, -8, -26, -28, -7, -30)
    ..cubicTo(14, -36, 31, -23, 33, -6)
    ..cubicTo(42, 14, 18, 27, 1, 26)
    ..cubicTo(-18, 29, -38, 22, -30, 7)
    ..close();
  fur(head, const Rect.fromLTWH(-35, -32, 72, 61));
  line(
    Path()
      ..moveTo(-9, -26)
      ..quadraticBezierTo(-6, -31, -3, -27)
      ..quadraticBezierTo(1, -33, 5, -29),
    const Color(0xFFFFFAED),
    3,
  );
  oval(const Rect.fromLTWH(-27, 10, 11, 5), const Color(0xFFE9B8AD));
  oval(const Rect.fromLTWH(18, 9, 11, 5), const Color(0xFFE9B8AD));
  for (final x in [-12.0, 13.0]) {
    oval(
      Rect.fromCenter(center: Offset(x, 1), width: 4.8, height: 5.7),
      const Color(0xFF303B31),
    );
    oval(
      Rect.fromCenter(center: Offset(x - .7, -.4), width: 1, height: 1),
      const Color(0xFFFFFBEC),
    );
  }
  fill(
    Path()
      ..moveTo(-2.8, 9)
      ..quadraticBezierTo(0, 7, 3, 9)
      ..quadraticBezierTo(0, 13, -2.8, 9)
      ..close(),
    const Color(0xFFB7837C),
  );
  line(
    Path()
      ..moveTo(0, 12)
      ..lineTo(0, 15)
      ..quadraticBezierTo(-3, 20, -6, 14)
      ..moveTo(0, 15)
      ..quadraticBezierTo(3, 20, 6, 14),
    const Color(0xFF786D59),
    1.55,
  );
  c.restore();

  // The board overlaps the chest. Rounded paws overlap both edges: held, not
  // floating in front of the rabbit. No ornament competes with the single kana.
  final board = RRect.fromRectAndRadius(
    const Rect.fromLTWH(37, 84, 54, 35),
    const Radius.circular(5),
  );
  c.drawRRect(
    board.shift(const Offset(0, 2)),
    p
      ..shader = null
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF8B5E36),
  );
  c.drawRRect(
    board,
    p
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4D49B), Color(0xFFE5B372)],
      ).createShader(board.outerRect)
      ..style = PaintingStyle.fill,
  );
  c.drawRRect(
    board,
    p
      ..shader = null
      ..color = const Color(0xFFAA7746)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );
  line(
    Path()
      ..moveTo(42, 89)
      ..quadraticBezierTo(46, 88, 49, 89)
      ..moveTo(79, 114)
      ..quadraticBezierTo(83, 113, 86, 114),
    const Color(0xFFCD985D),
    .8,
  );
  final letter = TextPainter(
    text: const TextSpan(
      text: 'あ',
      style: TextStyle(
        fontFamily: 'IconKana',
        fontSize: 32,
        height: 1,
        fontWeight: FontWeight.w700,
        color: Color(0xFF51391F),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  letter.paint(c, Offset(64 - letter.width / 2, 101.5 - letter.height / 2));
  letter.dispose();
  for (final x in [36.0, 92.0]) {
    final paw = Path()
      ..moveTo(x - 4, 91)
      ..cubicTo(x - 9, 92, x - 9, 102, x - 3, 105)
      ..cubicTo(x + 4, 108, x + 8, 100, x + 5, 95)
      ..quadraticBezierTo(x + 2, 90, x - 4, 91)
      ..close();
    fur(paw, Rect.fromLTWH(x - 9, 90, 18, 18));
  }
  c.restore();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('専用ベクターから通常・Adaptive・マスク確認用アイコンを書き出す', () async {
    final loader = FontLoader('IconKana')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/ZenMaruGothic-Bold.ttf').readAsBytesSync(),
          ),
        ),
      );
    await loader.load();
    Future<void> render(
      int size,
      String path, {
      bool foreground = false,
      String? mask,
    }) async {
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder)..scale(size / 128);
      if (mask == 'circle') {
        c.clipPath(Path()..addOval(const Rect.fromLTWH(0, 0, 128, 128)));
      }
      if (mask == 'rounded') {
        c.clipRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 128, 128),
            const Radius.circular(28),
          ),
        );
      }
      drawIcon(c, foreground: foreground);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      if (foreground) {
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final radius = size * 66 / 108 / 2;
        var furthestSquared = 0.0;
        for (var y = 0; y < size; y++) {
          for (var x = 0; x < size; x++) {
            if (rgba!.getUint8((y * size + x) * 4 + 3) <= 16) continue;
            final dx = x + .5 - size / 2, dy = y + .5 - size / 2;
            final squared = dx * dx + dy * dy;
            if (squared > furthestSquared) furthestSquared = squared;
          }
        }
        expect(
          furthestSquared,
          lessThanOrEqualTo(radius * radius),
          reason: 'Adaptive foreground must remain in the 66dp safe circle',
        );
      }
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    for (final entry in {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries) {
      await render(
        entry.value,
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      );
    }
    await render(
      432,
      'android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png',
      foreground: true,
    );
    await render(1024, 'assets/branding/app-icon.png');
    await render(512, 'assets/branding/app-icon-circle.png', mask: 'circle');
    await render(512, 'assets/branding/app-icon-rounded.png', mask: 'rounded');
    // A contact sheet shows actual 48px/64px icons without upscaling them.
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder)
      ..drawColor(const Color(0xFFFAF6EA), BlendMode.src);
    for (final entry in [48.0, 64.0, 96.0, 128.0].indexed) {
      final size = entry.$2;
      c.save();
      c.translate(20 + entry.$1 * 144.0, 20);
      c.scale(size / 128);
      c.clipPath(Path()..addOval(const Rect.fromLTWH(0, 0, 128, 128)));
      drawIcon(c);
      c.restore();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(600, 168);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      'assets/branding/app-icon-sizes.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
}

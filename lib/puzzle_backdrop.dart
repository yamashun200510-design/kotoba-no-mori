import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Quiet artwork at the edges; the answer and keyboard stay unobstructed.
class PuzzleBackdrop extends StatelessWidget {
  const PuzzleBackdrop({super.key});
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(child: CustomPaint(painter: _ForestPage())),
      ),
    ),
  );
}

class _ForestPage extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..isAntiAlias = true;
    c.drawRect(
      Offset.zero & s,
      p
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x24EAF3DF), Color(0x24FFF7DF), Color(0x40F8E8DD)],
        ).createShader(Offset.zero & s),
    );
    p.shader = null;
    for (var i = 0; i < 7; i++) {
      final x = i.isEven ? 6.0 : s.width - 6;
      final y = 20.0 + i * 25;
      c.save();
      c.translate(x, y);
      c.rotate(i.isEven ? -.7 : .7);
      c.drawPath(
        Path()
          ..moveTo(0, 15)
          ..quadraticBezierTo(-17, -6, 0, -21)
          ..quadraticBezierTo(18, -4, 0, 15),
        p..color = i.isEven ? const Color(0xFFB5D6A2) : const Color(0xFFCBDD9E),
      );
      c.restore();
    }
    for (var i = 0; i < 3; i++) {
      final center = Offset(i == 1 ? s.width - 17 : 17, 108.0 + i * 40);
      for (var petal = 0; petal < 5; petal++) {
        final a = petal * math.pi * 2 / 5;
        c.drawOval(
          Rect.fromCenter(
            center: center + Offset(math.cos(a) * 6, math.sin(a) * 6),
            width: 9,
            height: 8,
          ),
          p
            ..color = [
              const Color(0xFFEAB3C3),
              const Color(0xFFEBC985),
              const Color(0xFFC2B5DF),
            ][i],
        );
      }
      c.drawCircle(center, 3, p..color = const Color(0xFFFFF4CB));
    }
    for (var i = 0; i < 8; i++) {
      c.drawCircle(
        Offset(s.width * (.12 + i * .11), 72 + (i % 3) * 33),
        i.isEven ? 3 : 2,
        p..color = const Color(0xFFFFFEED).withValues(alpha: .8),
      );
    }
    final b = Offset(s.width - 42, 110);
    c.save();
    c.translate(b.dx, b.dy);
    c.rotate(-.3);
    p.color = const Color(0xFFE4AD79);
    c.drawOval(const Rect.fromLTWH(-13, -10, 13, 14), p);
    p.color = const Color(0xFFF0C8A3);
    c.drawOval(const Rect.fromLTWH(1, -10, 13, 14), p);
    c.drawLine(
      const Offset(0, -7),
      const Offset(0, 7),
      p
        ..color = const Color(0xFF846646)
        ..strokeWidth = 2,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(_ForestPage oldDelegate) => false;
}

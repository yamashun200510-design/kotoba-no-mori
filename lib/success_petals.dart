import 'dart:math' as math;
import 'package:flutter/material.dart';

class SuccessPetals extends StatefulWidget {
  const SuccessPetals({super.key});
  @override
  State<SuccessPetals> createState() => _SuccessPetalsState();
}

class _SuccessPetalsState extends State<SuccessPetals>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(child: CustomPaint(painter: _Petals(motion))),
  );
}

class _Petals extends CustomPainter {
  final Animation<double> motion;
  _Petals(this.motion) : super(repaint: motion);
  @override
  void paint(Canvas canvas, Size size) {
    final t = motion.value;
    final p = Paint()..isAntiAlias = true;
    for (var i = 0; i < 19; i++) {
      final phase = (t - (i % 4) * .05).clamp(0.0, 1.0);
      final x =
          size.width * ((i * 37 % 95 + 3) / 100) + math.sin(phase * 4 + i) * 15;
      final y = size.height * .38 - phase * 100 + math.sin(i.toDouble()) * 35;
      p.color = (i.isEven ? const Color(0xFFE9B7BF) : const Color(0xFFE9C979))
          .withValues(alpha: math.sin(phase * math.pi) * .7);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(phase * 2 + i);
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 2.5, p);
      } else {
        canvas.drawPath(
          Path()
            ..moveTo(0, -5)
            ..cubicTo(-8, -1, -4, 6, 0, 4)
            ..cubicTo(5, 6, 7, -2, 0, -5)
            ..close(),
          p,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Petals old) => old.motion != motion;
}

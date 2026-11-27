import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Full-screen pink-petal wipe used when leaving the title.
/// Timeline (~2.2s): petals drift in and fully cover the screen, [onCovered]
/// fires at the opaque moment (swap the screen underneath), then the petals
/// stream off to the left and right, revealing the new screen. [onDone] fires
/// at the end so the overlay can be removed and the controller disposed.
class PetalTransition extends StatefulWidget {
  final VoidCallback onCovered;
  final VoidCallback onDone;
  const PetalTransition({
    super.key,
    required this.onCovered,
    required this.onDone,
  });
  @override
  State<PetalTransition> createState() => _PetalTransitionState();
}

class _PetalTransitionState extends State<PetalTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController c;
  bool covered = false;
  late final List<_Petal> petals;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(11);
    petals = List.generate(120, (i) {
      return _Petal(
        x: rnd.nextDouble(),
        y: rnd.nextDouble(),
        enterDx: rnd.nextDouble() * 1.3 - 0.15,
        enterDy: -0.25 - rnd.nextDouble() * 0.6,
        size: 11 + rnd.nextDouble() * 17,
        rot: rnd.nextDouble() * math.pi * 2,
        spin: (rnd.nextDouble() * 2 - 1) * 5,
        tint: rnd.nextInt(_tints.length),
        toLeft: rnd.nextBool(),
        delay: rnd.nextDouble() * 0.16,
      );
    });
    c =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2200),
        )
        ..addListener(() {
          if (!covered && c.value >= 0.46) {
            covered = true;
            widget.onCovered();
          }
        })
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _PetalPainter(c, petals),
      ),
    ),
  );
}

const _tints = [
  Color(0xFFFFC2D6),
  Color(0xFFFFB0C8),
  Color(0xFFFFD3E0),
  Color(0xFFFF9FBE),
  Color(0xFFFFE1EC),
];

class _Petal {
  final double x, y, enterDx, enterDy, size, rot, spin, delay;
  final int tint;
  final bool toLeft;
  const _Petal({
    required this.x,
    required this.y,
    required this.enterDx,
    required this.enterDy,
    required this.size,
    required this.rot,
    required this.spin,
    required this.tint,
    required this.toLeft,
    required this.delay,
  });
}

class _PetalPainter extends CustomPainter {
  final Animation<double> t;
  final List<_Petal> petals;
  _PetalPainter(this.t, this.petals) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size s) {
    final v = t.value;
    // Cover progress 0->1 (first ~half), reveal progress 0->1 (second ~half).
    final cover = (v / 0.46).clamp(0.0, 1.0);
    final reveal = ((v - 0.54) / 0.46).clamp(0.0, 1.0);
    // A soft pink veil guarantees the screen is fully opaque at the swap moment,
    // so the home screen never peeks through before it is covered.
    final veil = reveal > 0
        ? (1 - Curves.easeIn.transform(reveal))
        : Curves.easeInCubic.transform(cover);
    if (veil > 0.001) {
      canvas.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD9E6), Color(0xFFFFC0D7)],
          ).createShader(Offset.zero & s)
          ..color = Colors.white.withValues(alpha: veil.clamp(0.0, 1.0)),
      );
    }
    final p = Paint()..isAntiAlias = true;
    for (final petal in petals) {
      // Enter: slide from an off-screen offset to the resting spot.
      final enter = Curves.easeOut.transform(
        ((cover - petal.delay) / (1 - petal.delay)).clamp(0.0, 1.0),
      );
      var cx = (petal.x + petal.enterDx * (1 - enter)) * s.width;
      var cy = (petal.y + petal.enterDy * (1 - enter)) * s.height;
      var alpha = enter;
      var angle = petal.rot + petal.spin * cover;
      if (reveal > 0) {
        // Exit: stream off to the left/right edge and fade out.
        final e = Curves.easeIn.transform(reveal);
        final target = (petal.toLeft ? -0.25 : 1.25) * s.width;
        cx = cx + (target - cx) * e;
        cy = cy + (petal.toLeft ? -40 : 30) * e;
        alpha = 1 - e;
        angle += petal.spin * reveal * 1.5;
      }
      if (alpha <= 0.02) continue;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      p.color = _tints[petal.tint].withValues(alpha: alpha.clamp(0.0, 1.0));
      final r = petal.size;
      // A simple rounded petal shape.
      final path = Path()
        ..moveTo(0, -r)
        ..cubicTo(r * .8, -r * .6, r * .7, r * .5, 0, r)
        ..cubicTo(-r * .7, r * .5, -r * .8, -r * .6, 0, -r)
        ..close();
      canvas.drawPath(path, p);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha * .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PetalPainter old) => false;
}

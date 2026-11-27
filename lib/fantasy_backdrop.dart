import 'dart:math' as math;
import 'package:flutter/material.dart';

/// UI-free cartoon artwork; only the sparse light/wing layer repaints.
class FantasyBackdrop extends StatefulWidget {
  final double veil;
  final bool animate;
  final String asset;
  final Alignment alignment;
  const FantasyBackdrop({
    super.key,
    this.veil = .12,
    this.animate = true,
    this.asset = 'assets/art/cartoon-home.png',
    this.alignment = Alignment.center,
  });
  @override
  State<FantasyBackdrop> createState() => _FantasyBackdropState();
}

class _FantasyBackdropState extends State<FantasyBackdrop>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController wind = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  bool active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    active = WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused;
  }

  void sync() {
    if (widget.animate &&
        active &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!wind.isAnimating) wind.repeat();
    } else {
      wind.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(FantasyBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    wind.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: Image.asset(
              widget.asset,
              fit: BoxFit.cover,
              alignment: widget.alignment,
              cacheWidth: 960,
              filterQuality: FilterQuality.medium,
            ),
          ),
          ColoredBox(
            color: const Color(0xFFFFFAE9).withValues(alpha: widget.veil),
          ),
          RepaintBoundary(
            child: CustomPaint(painter: _ForestLight(wind, widget.veil)),
          ),
        ],
      ),
    ),
  );
}

class _ForestLight extends CustomPainter {
  final Animation<double> wind;
  final double veil;
  _ForestLight(this.wind, this.veil) : super(repaint: wind);
  @override
  void paint(Canvas c, Size s) {
    final t = wind.value * math.pi * 2;
    final p = Paint()..isAntiAlias = true;
    final gust = (math.sin(t * .37 - .8) + 1) / 2;
    _paintSwayingSprig(
      c,
      Offset(-48, s.height * .09),
      math.sin(t + .3) * (.055 + gust * .035),
      const Color(0xFF26744B),
    );
    for (var i = 0; i < 3; i++) {
      final dx = math.sin(t + i) * s.width * .025;
      final path = Path()
        ..moveTo(s.width * .25, 0)
        ..lineTo(s.width * (.35 + i * .15) + dx, s.height * .65)
        ..lineTo(s.width * (.43 + i * .15) + dx, s.height * .65)
        ..close();
      c.drawPath(
        path,
        p
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(
                0xFFFFEDAD,
              ).withValues(alpha: .08 + .02 * math.sin(t + i)),
              Colors.transparent,
            ],
          ).createShader(Offset.zero & s),
      );
    }
    p.shader = null;
    for (var i = 0; i < 7; i++) {
      final x = s.width * (.08 + (i % 2) * .83) + math.sin(t + i) * 12;
      final y = s.height * (.18 + i * .095) + math.cos(t + i * .7) * 14;
      p.color = (i.isEven ? const Color(0xFFFFE2A0) : const Color(0xFFF5BBCE))
          .withValues(alpha: (1 - veil) * .65);
      c.save();
      c.translate(x, y);
      c.rotate(math.sin(t + i) * .5);
      c.drawOval(const Rect.fromLTWH(-3, -5, 6, 10), p);
      c.restore();
    }
    for (var i = 0; i < 2; i++) {
      c.save();
      c.translate(
        s.width * (i == 0 ? .08 : .92) + math.sin(t + i * 2) * 17,
        s.height * (.3 + i * .32) + math.sin(t * 2 + i) * 20,
      );
      c.rotate(math.sin(t + i) * .2);
      c.scale(.5 + .4 * math.sin(t * 8 + i).abs(), 1);
      p.color = i == 0 ? const Color(0xFFEABD70) : const Color(0xFFC09CCF);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..cubicTo(-16, -20, -22, 8, 0, 6)
          ..cubicTo(22, 8, 16, -20, 0, 0),
        p,
      );
      c.drawLine(
        const Offset(0, -4),
        const Offset(0, 7),
        p
          ..color = const Color(0xFF765C43)
          ..strokeWidth = 1.5,
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_ForestLight oldDelegate) =>
      wind != oldDelegate.wind || veil != oldDelegate.veil;

  void _paintSwayingSprig(
    Canvas canvas,
    Offset origin,
    double angle,
    Color leafColor,
  ) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(.68);
    canvas.rotate(angle);
    final twig = Paint()
      ..color = const Color(0xFF76563A).withValues(alpha: .48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-8, -3)
        ..cubicTo(35, 12, 50, 54, 111, 88)
        ..cubicTo(128, 98, 143, 117, 158, 135),
      twig,
    );
    final leaf = Paint()..isAntiAlias = true;
    const leaves = <(double, double, double, double, int)>[
      (20, 17, 34, 18, 0),
      (45, 35, 34, 19, 1),
      (66, 52, 37, 20, 0),
      (88, 69, 34, 18, 1),
      (111, 91, 31, 17, 0),
      (35, 52, 29, 17, 1),
      (74, 81, 31, 18, 0),
      (120, 119, 27, 15, 1),
    ];
    for (var i = 0; i < leaves.length; i++) {
      final (x, y, w, h, side) = leaves[i];
      final flutter = math.sin(wind.value * math.pi * 2 + i * 1.13) * .11;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((side == 0 ? -.52 : .52) + flutter);
      leaf.color = Color.lerp(
        leafColor,
        i.isEven ? const Color(0xFF91C953) : const Color(0xFF55A85D),
        i % 3 * .22,
      )!.withValues(alpha: .74);
      final path = Path()
        ..moveTo(-w / 2, 0)
        ..quadraticBezierTo(-w * .3, -h * .72, 1, -h / 2)
        ..quadraticBezierTo(w * .48, -h * .12, w / 2, 0)
        ..quadraticBezierTo(w * .22, h * .65, -2, h / 2)
        ..quadraticBezierTo(-w * .42, h * .25, -w / 2, 0)
        ..close();
      canvas.drawPath(path, leaf);
      canvas.drawLine(
        Offset(-w * .35, 0),
        Offset(w * .36, 0),
        Paint()
          ..color = const Color(0xFFD7E99B).withValues(alpha: .6)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }
    canvas.restore();
  }
}

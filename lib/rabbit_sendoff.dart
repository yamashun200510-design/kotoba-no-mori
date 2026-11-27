import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'rabbit_mascot.dart';

/// A short, disposable transition: no saved state or game/reward logic.
class RabbitSendoff extends StatefulWidget {
  final VoidCallback onComplete;
  const RabbitSendoff({super.key, required this.onComplete});
  @override
  State<RabbitSendoff> createState() => _RabbitSendoffState();
}

class _RabbitSendoffState extends State<RabbitSendoff>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool finished = false;
  void finish() {
    if (!mounted || finished) return;
    finished = true;
    widget.onComplete();
  }

  @override
  void initState() {
    super.initState();
    motion.addStatusListener((status) {
      if (status == AnimationStatus.completed) finish();
    });
    motion.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => finish());
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlockSemantics(
    child: Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.transparent),
        Positioned.fill(
          child: IgnorePointer(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final height = math.min(220.0, bounds.maxHeight * .52);
                  return AnimatedBuilder(
                    animation: motion,
                    builder: (context, child) {
                      final t = motion.value;
                      final entrance = Curves.easeOutBack.transform(
                        (t / .24).clamp(0, 1),
                      );
                      final fade = t < .88
                          ? 1.0
                          : ((1 - t) / .12).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: fade,
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: height + 100,
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: _SendoffPetals(motion),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  (1 - entrance) * (height + 100),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: bounds.maxWidth * .88,
                                        ),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF8E5),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF9CAD83),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              'いってらっしゃい！',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'ZenMaru',
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.none,
                                                color: Color(0xFF35634C),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const CustomPaint(
                                        size: Size(22, 10),
                                        painter: _BubbleTail(),
                                      ),
                                      RabbitMascot(
                                        key: const ValueKey('sendoff-rabbit'),
                                        mood: RabbitMood.farewell,
                                        width: height * 2 / 3,
                                        height: height,
                                        animateIdle: false,
                                        interactive: false,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _BubbleTail extends CustomPainter {
  const _BubbleTail();
  @override
  void paint(Canvas c, Size s) {
    final path = Path()
      ..moveTo(0, -1)
      ..lineTo(s.width / 2, s.height)
      ..lineTo(s.width, -1);
    c.drawPath(path, Paint()..color = const Color(0xFFFFF8E5));
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF9CAD83)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BubbleTail oldDelegate) => false;
}

class _SendoffPetals extends CustomPainter {
  final Animation<double> motion;
  _SendoffPetals(this.motion) : super(repaint: motion);
  @override
  void paint(Canvas c, Size s) {
    final t = motion.value;
    final p = Paint()..isAntiAlias = true;
    const colors = [
      Color(0xFFE7A0B7),
      Color(0xFFECC465),
      Color(0xFFA58BC9),
      Color(0xFF8EBB9B),
    ];
    for (var i = 0; i < 9; i++) {
      final phase = ((t - .12 - i % 3 * .035) / .88).clamp(0.0, 1.0);
      p.color = colors[i % colors.length].withValues(
        alpha: math.sin(phase * math.pi) * .85,
      );
      c.save();
      c.translate(
        s.width * (.22 + (i * 37 % 57) / 100) + math.sin(phase * 3 + i) * 13,
        s.height * .8 - phase * (100 + i % 3 * 22),
      );
      c.rotate(phase * 2 + i);
      c.drawPath(
        Path()
          ..moveTo(0, -6)
          ..cubicTo(-8, -2, -5, 6, 0, 5)
          ..cubicTo(6, 6, 8, -2, 0, -6)
          ..close(),
        p,
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_SendoffPetals old) => motion != old.motion;
}

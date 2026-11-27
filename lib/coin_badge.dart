import 'package:flutter/material.dart';

/// The saved balance is announced immediately; only earned coins count upward.
class CoinBadge extends StatefulWidget {
  final int coins;
  const CoinBadge({super.key, required this.coins});
  @override
  State<CoinBadge> createState() => _CoinBadgeState();
}

class _CoinBadgeState extends State<CoinBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  late int from = widget.coins;
  int get displayed =>
      (from + (widget.coins - from) * Curves.easeOut.transform(motion.value))
          .round();
  @override
  void didUpdateWidget(CoinBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coins == widget.coins) return;
    final current =
        (from +
                (oldWidget.coins - from) *
                    Curves.easeOut.transform(motion.value))
            .round();
    if (widget.coins > oldWidget.coins &&
        !MediaQuery.disableAnimationsOf(context)) {
      from = current;
      motion.forward(from: 0);
    } else {
      from = widget.coins;
      motion.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) motion.value = 1;
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('coin-balance'),
    label: '所持コイン ${widget.coins}枚',
    liveRegion: true,
    child: ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 76,
          maxWidth: 136,
          minHeight: 42,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0C9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD8BB79)),
        ),
        child: AnimatedBuilder(
          animation: motion,
          builder: (context, child) => FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CoinGlyph(),
                const SizedBox(width: 6),
                Text(
                  '$displayed',
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF67471E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class CoinGlyph extends StatelessWidget {
  const CoinGlyph({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 24,
    height: 24,
    child: CustomPaint(painter: _CoinPaint()),
  );
}

class _CoinPaint extends CustomPainter {
  const _CoinPaint();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final brush = Paint()..isAntiAlias = true;
    canvas.drawCircle(
      const Offset(12, 13),
      10.5,
      brush..color = const Color(0xFFC39540),
    );
    canvas.drawCircle(
      const Offset(12, 11.5),
      10.5,
      brush
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFDF88), Color(0xFFE7B753)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(0, 0, 24, 24)),
    );
    brush.shader = null;
    canvas.drawCircle(
      const Offset(12, 11.5),
      7.8,
      brush
        ..color = const Color(0xFFC69843)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    canvas.drawPath(
      Path()
        ..moveTo(8, 15)
        ..cubicTo(7, 8, 12, 7, 16, 6)
        ..cubicTo(17, 12, 14, 16, 8, 15)
        ..close(),
      brush
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFAA7B2F),
    );
    canvas.drawLine(
      const Offset(8, 17),
      const Offset(14, 9),
      brush
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CoinPaint oldDelegate) => false;
}

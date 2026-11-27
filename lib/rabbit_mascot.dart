import 'dart:math' as math;
import 'package:flutter/material.dart';

enum RabbitMood { idle, greeting, happy, bow, present, farewell }

/// Original articulated mascot. Only its paint layer redraws during animation.
class RabbitMascot extends StatefulWidget {
  final RabbitMood mood;
  final int event;
  final double width, height;
  final bool animateIdle, interactive;
  const RabbitMascot({
    super.key,
    this.mood = RabbitMood.idle,
    this.event = 0,
    this.width = 96,
    this.height = 128,
    this.animateIdle = true,
    this.interactive = true,
  });
  @override
  State<RabbitMascot> createState() => _RabbitMascotState();

  // The forest uses exactly the same character drawing at a smaller scale.
  static void paintInForest(Canvas canvas, Offset feet, {double seconds = 0}) {
    canvas.save();
    canvas.translate(feet.dx - 29, feet.dy - 76);
    _RabbitPainter.draw(
      canvas,
      const Size(58, 80),
      _Pose.at(seconds, 1, RabbitMood.idle, false),
    );
    canvas.restore();
  }
}

class _RabbitMascotState extends State<RabbitMascot>
    with TickerProviderStateMixin {
  late final AnimationController clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 47),
  );
  late final AnimationController action = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: widget.mood == RabbitMood.happy ? 1100 : 1500,
    ),
    value: 1,
  );
  late RabbitMood reaction = widget.mood;
  bool quiet = true, started = false;
  void playReaction() {
    action.duration = Duration(
      milliseconds: reaction == RabbitMood.farewell
          ? 1200
          : reaction == RabbitMood.happy
          ? 1100
          : reaction == RabbitMood.greeting
          ? 1000
          : 1500,
    );
    action.forward(from: 0);
  }

  void syncMotion() {
    quiet =
        MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled;
    if (quiet) {
      clock.stop();
      action.value = 1;
    } else {
      if (widget.animateIdle && !clock.isAnimating) clock.repeat();
      if (!widget.animateIdle) clock.stop();
      if (!started && widget.mood != RabbitMood.idle) playReaction();
    }
    started = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncMotion();
  }

  @override
  void didUpdateWidget(RabbitMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncMotion();
    if (widget.mood != oldWidget.mood || widget.event != oldWidget.event) {
      reaction = widget.mood;
      if (!quiet) playReaction();
    }
  }

  void greet() {
    setState(() => reaction = RabbitMood.greeting);
    if (!quiet) playReaction();
  }

  @override
  void dispose() {
    clock.dispose();
    action.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.interactive ? '白いうさぎのことまる。タップしてごあいさつ' : '森の白うさぎ、ことまる',
    button: widget.interactive,
    onTap: widget.interactive ? greet : null,
    child: GestureDetector(
      onTap: widget.interactive ? greet : null,
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: _RabbitPainter(
              clock,
              action,
              reaction,
              widget.mood == RabbitMood.present,
              quiet,
            ),
          ),
        ),
      ),
    ),
  );
}

class _Pose {
  final double blink,
      breath,
      leftEar,
      rightEar,
      tilt,
      turn,
      hop,
      bow,
      smile,
      gift,
      waveAngle;
  const _Pose({
    this.blink = 0,
    this.breath = 0,
    this.leftEar = 0,
    this.rightEar = 0,
    this.tilt = 0,
    this.turn = 0,
    this.hop = 0,
    this.bow = 0,
    this.smile = 0,
    this.gift = 0,
    this.waveAngle = 0,
  });
  static double pulse(double t, double center, double width) =>
      math.max(0, 1 - (t - center).abs() / width);
  static _Pose at(
    double seconds,
    double progress,
    RabbitMood mood,
    bool quiet, {
    bool holdGift = false,
  }) {
    final t = seconds % 47;
    var blink = 0.0;
    for (final moment in [2.6, 7.9, 8.25, 14.8, 21.5, 29.1, 33.7, 42.4]) {
      final dt = t - moment;
      // Close decisively, hold briefly, then open gently (no flash-like blink).
      final lid = dt < -.12 || dt > .25
          ? 0.0
          : dt < 0
          ? Curves.easeOut.transform((dt + .12) / .12)
          : dt < .10
          ? 1.0
          : 1 - Curves.easeInOut.transform((dt - .10) / .15);
      blink = math.max(blink, lid);
    }
    final envelope = math.sin(math.pi * progress).clamp(0.0, 1.0);
    final greeting = mood == RabbitMood.greeting
        ? (quiet
              ? .5
              : progress < .2
              ? Curves.easeOut.transform(progress / .2)
              : progress < .55
              ? 1.0
              : Curves.easeInOut.transform(((1 - progress) / .45).clamp(0, 1)))
        : 0.0;
    final happy = mood == RabbitMood.happy ? (quiet ? .45 : envelope) : 0.0;
    final bow = mood == RabbitMood.bow
        ? (quiet ? .3 : math.pow(envelope, 1.5).toDouble())
        : 0.0;
    final gift = mood == RabbitMood.present || holdGift
        ? (quiet ? 1.0 : Curves.easeInOut.transform(progress.clamp(0, 1)))
        : 0.0;
    final twitch = quiet
        ? 0.0
        : pulse(t, 5.4, .45) * math.sin((t - 5.4) * 13) +
              pulse(t, 24.2, .6) * math.sin((t - 24.2) * 10);
    double gesture(double center, double width) =>
        Curves.easeInOut.transform(pulse(t, center, width));
    final listenLeft = quiet ? 0.0 : gesture(5.4, 1.3) + gesture(31.5, 1.6);
    final listenRight = quiet ? 0.0 : gesture(17.3, 1.5) + gesture(40.2, 1.4);
    final curious = quiet
        ? 0.0
        : gesture(9.8, 1.7) * .14 -
              gesture(19.4, 2.0) * .12 +
              gesture(28.0, 1.6) * .13 -
              gesture(43.8, 1.8) * .14;
    final farewell = mood == RabbitMood.farewell && !quiet;
    final lift = !farewell
        ? 0.0
        : progress < .28
        ? Curves.easeOut.transform(((progress - .10) / .18).clamp(0, 1))
        : progress < .84
        ? 1.0
        : Curves.easeIn.transform(((1 - progress) / .16).clamp(0, 1));
    final wave = math.sin(((progress - .28) / .56).clamp(0, 1) * math.pi * 4);
    return _Pose(
      blink: quiet ? 0 : blink,
      breath: quiet
          ? 0
          : math.sin(t * math.pi * 2 / 4.9) * .028 + math.sin(t * 1.7) * .004,
      leftEar:
          lift * math.sin(progress * math.pi * 4) * .17 +
          twitch * .16 -
          listenLeft * .38 +
          greeting * -.17 +
          (quiet ? 0 : math.sin(progress * math.pi * 3) * happy * .24),
      rightEar:
          lift * math.sin(progress * math.pi * 4 + .5) * -.21 -
          twitch * .10 +
          listenRight * .36 +
          happy * .25 +
          greeting * .18,
      tilt: curious * (1 - greeting) + greeting * -.24 + bow * .09,
      turn: greeting,
      hop: quiet
          ? 0
          : math.sin(((progress - .15) / .65).clamp(0, 1) * math.pi) *
                happy *
                24,
      bow: bow,
      smile: math.max(
        lift * .8,
        math.max(greeting, math.max(happy, gift * .5)),
      ),
      gift: gift,
      waveAngle: lift * (-2.2 + wave * .32),
    );
  }
}

class _RabbitPainter extends CustomPainter {
  final Animation<double> clock, action;
  final RabbitMood mood;
  final bool gift, quiet;
  _RabbitPainter(this.clock, this.action, this.mood, this.gift, this.quiet)
    : super(repaint: Listenable.merge([clock, action]));
  @override
  void paint(Canvas canvas, Size size) => draw(
    canvas,
    size,
    _Pose.at(clock.value * 47, action.value, mood, quiet, holdGift: gift),
    celebration: mood == RabbitMood.happy && !quiet,
  );

  static void draw(
    Canvas c,
    Size size,
    _Pose pose, {
    bool celebration = false,
  }) {
    const ink = Color(0xFF353D33),
        edge = Color(0xFFD9CDB8),
        cream = Color(0xFFFFF7E8);
    final p = Paint()..isAntiAlias = true;
    void fill(Path shape, Color color) => c.drawPath(
      shape,
      p
        ..style = PaintingStyle.fill
        ..color = color,
    );
    void line(Path path, Color color, double width) => c.drawPath(
      path,
      p
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    void oval(double x, double y, double w, double h, Color color) =>
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: w, height: h),
          p
            ..style = PaintingStyle.fill
            ..color = color,
        );
    void fur(Path shape, Rect bounds) {
      c.drawPath(
        shape,
        p
          ..style = PaintingStyle.fill
          ..color = Colors.white
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFCF4), Color(0xFFF4E7D2)],
          ).createShader(bounds),
      );
      p.shader = null;
      line(shape, edge, .9);
    }

    void leaf(double x, double y, double angle, double scale, Color color) {
      c.save();
      c.translate(x, y);
      c.rotate(angle);
      c.scale(scale);
      final shape = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-18, -5, -16, -22)
        ..quadraticBezierTo(0, -25, 0, 0)
        ..quadraticBezierTo(2, -19, 16, -22)
        ..quadraticBezierTo(17, -5, 0, 0)
        ..close();
      fill(shape, color);
      line(
        Path()
          ..moveTo(0, -1)
          ..quadraticBezierTo(-1, -12, -13, -20)
          ..moveTo(0, -1)
          ..quadraticBezierTo(2, -13, 13, -20),
        const Color(0xFF4E7543),
        1.1,
      );
      c.restore();
    }

    void flower(double x, double y, double radius, Color petalColor) {
      for (var i = 0; i < 5; i++) {
        final a = i * math.pi * 2 / 5 - math.pi / 2;
        oval(
          x + math.cos(a) * radius * .72,
          y + math.sin(a) * radius * .72,
          radius * .82,
          radius * .66,
          petalColor,
        );
      }
      oval(x, y, radius * .58, radius * .58, const Color(0xFFFFD66E));
      oval(
        x - radius * .08,
        y - radius * .10,
        radius * .14,
        radius * .14,
        const Color(0xFFFFF5D7),
      );
    }

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
          ..moveTo(-3, -7)
          ..cubicTo(-8, -length * .45, -6, -length + 10, -1, -length + 9)
          ..cubicTo(5, -length + 10, 9, -length * .45, 3, -7)
          ..close(),
        const Color(0xFFEAC0BA),
      );
      line(
        Path()
          ..moveTo(-1, -12)
          ..quadraticBezierTo(-3, -length * .5, -2, -length + 15),
        const Color(0xFFF6D7CC),
        2,
      );
      c.restore();
    }

    c.save();
    // Reserve jump headroom without moving the feet or changing widget layout.
    final scale = math.min(
      size.width / 120,
      size.height / (celebration ? 200 : 180),
    );
    c.translate(
      (size.width - 112 * scale) / 2,
      (size.height - 166 * scale) / 2,
    );
    c.scale(scale);
    if (celebration) c.translate(0, 8);
    // Grounding shadow: a soft wide halo plus a darker contact core so the
    // mascot reads as sitting on the ground, not floating over the artwork.
    oval(57, 156, 70 - pose.hop, 11, const Color(0x2E3A5230));
    oval(57, 157, 46 - pose.hop * .7, 8, const Color(0x55344B2B));
    c.translate(55, 151 - pose.hop - pose.breath * 28);
    c.rotate(pose.bow * .035);
    c.scale(1 - pose.breath * .35, 1 + pose.breath);
    // The leafy mantle peeks out around the soft body and gives Kotomaru a
    // distinct woodland silhouette matching the character sheet.
    final mantle = Path()
      ..moveTo(-24, -62)
      ..quadraticBezierTo(-43, -54, -39, -30)
      ..quadraticBezierTo(-39, -12, -28, -8)
      ..quadraticBezierTo(-22, -17, -17, -8)
      ..quadraticBezierTo(-7, -15, 0, -7)
      ..quadraticBezierTo(10, -15, 19, -7)
      ..quadraticBezierTo(27, -17, 34, -10)
      ..quadraticBezierTo(45, -30, 34, -51)
      ..quadraticBezierTo(22, -67, 12, -66)
      ..close();
    fill(mantle, const Color(0xFF668C4A));
    line(mantle, const Color(0xFF476D38), 1.4);
    leaf(-31, -25, -.42, .48, const Color(0xFFA8C96C));
    leaf(31, -30, .45, .48, const Color(0xFF9DBF5F));
    leaf(-18, -61, -.65, .52, const Color(0xFF82A953));
    leaf(16, -63, .7, .5, const Color(0xFF9BBE62));
    oval(34, -22, 20, 21, edge);
    oval(33, -23, 18, 20, cream);
    final body = Path()
      ..moveTo(-29, -4)
      ..cubicTo(-40, -21, -29, -59, -12, -68)
      ..cubicTo(4, -79, 29, -61, 32, -36)
      ..cubicTo(39, -11, 25, 2, 1, 1)
      ..quadraticBezierTo(-19, 5, -29, -4)
      ..close();
    fur(body, const Rect.fromLTWH(-35, -72, 70, 76));
    oval(0, -26, 35, 39, const Color(0x60FFFDF4));
    // Warm cream belly, softly shaded so the character feels plush rather
    // than like a flat white icon.
    oval(1, -20, 27, 36, const Color(0x55E9D8B9));
    oval(-18, -1, 25, 12, cream);
    oval(18, -1, 26, 12, cream);
    line(
      Path()
        ..moveTo(-26, 2)
        ..quadraticBezierTo(-18, 7, -8, 3)
        ..moveTo(9, 4)
        ..quadraticBezierTo(20, 8, 29, 1),
      edge,
      1,
    );
    c.save();
    c.translate(pose.turn * 1.5, -76 + pose.bow * 9 - pose.breath * 30);
    c.rotate(pose.tilt);
    ear(-17, -15, -.13 + pose.leftEar + pose.bow * .13, 54);
    ear(15, -17, .12 + pose.rightEar + pose.bow * .2, 58);
    final head = Path()
      ..moveTo(-30, 7)
      ..cubicTo(-37, -8, -26, -28, -7, -30)
      ..cubicTo(14, -36, 31, -23, 33, -6)
      ..cubicTo(42, 14, 18, 27, 1, 26)
      ..cubicTo(-18, 29, -38, 22, -30, 7)
      ..close();
    fur(head, const Rect.fromLTWH(-35, -32, 72, 61));
    // A tiny uneven forelock keeps the silhouette from becoming a round icon.
    line(
      Path()
        ..moveTo(-9, -26)
        ..quadraticBezierTo(-6, -31, -3, -27)
        ..quadraticBezierTo(1, -33, 5, -29),
      cream,
      3,
    );
    // A leafy headband and tiny blossoms are the signature of ことまる.
    leaf(-25, -20, -.95, .42, const Color(0xFF6E9848));
    leaf(-18, -27, -.60, .38, const Color(0xFFA2C567));
    leaf(-10, -29, -.24, .34, const Color(0xFF83A957));
    flower(-27, -29, 7.2, const Color(0xFFFFF7E8));
    flower(-16, -34, 5.4, const Color(0xFFF6C7BD));
    final look = pose.turn * 1.8;
    // Rounder, rosier cheeks for extra charm.
    oval(-24 + look, 12, 11.5, 6, const Color(0xB8EFA9A0));
    oval(24 + look, 11, 11.5, 6, const Color(0xB8EFA9A0));
    for (final x in [-12.5, 13.5]) {
      if (pose.blink > .75) {
        line(
          Path()
            ..moveTo(x - 3 + look, 1)
            ..quadraticBezierTo(x + look, 3.4, x + 3 + look, 1),
          ink,
          1.8,
        );
      } else {
        // Bigger, ぱっちり eyes with a bright highlight and a soft lower glint.
        oval(x + look, 1.4, 5.4, 6.3 * (1 - pose.blink) + .3, ink);
        if (pose.blink < .35) {
          oval(x - 1.6 + look, -1.4, 2.0, 2.3, const Color(0xFFFFFDF2));
          oval(x + 1.8 + look, 3.1, 1.0, 1.1, const Color(0x80FFFFFF));
        }
      }
    }
    fill(
      Path()
        ..moveTo(-2.8 + look, 9)
        ..quadraticBezierTo(look, 7, 3 + look, 9)
        ..quadraticBezierTo(look, 13, -2.8 + look, 9)
        ..close(),
      const Color(0xFFBC8A83),
    );
    line(
      Path()
        ..moveTo(look, 12)
        ..lineTo(look, 15)
        ..quadraticBezierTo(
          -3 + look,
          18 + pose.smile * 2,
          -6 + look,
          15 - pose.smile * 2,
        )
        ..moveTo(look, 15)
        ..quadraticBezierTo(
          3 + look,
          18 + pose.smile * 2,
          6 + look,
          15 - pose.smile * 2,
        ),
      const Color(0xFF8F8170),
      1.1,
    );
    c.restore();
    // A little leaf collar sits below the chin; it remains behind the arms.
    fill(
      Path()
        ..moveTo(-21, -55)
        ..quadraticBezierTo(-4, -47, 17, -56)
        ..quadraticBezierTo(13, -44, 4, -42)
        ..quadraticBezierTo(-9, -44, -21, -55)
        ..close(),
      const Color(0xFF6F9849),
    );
    leaf(-12, -47, -.55, .33, const Color(0xFFB4D477));
    leaf(3, -45, .55, .32, const Color(0xFF9FC566));
    // Cross-body strap and flowered acorn-shaped satchel from the reference.
    line(
      Path()
        ..moveTo(-19, -62)
        ..quadraticBezierTo(-3, -40, 24, -20),
      const Color(0xFF795334),
      4.2,
    );
    line(
      Path()
        ..moveTo(-19, -63)
        ..quadraticBezierTo(-3, -41, 24, -21),
      const Color(0xFFEBCB91),
      2.4,
    );
    final pouch = Path()
      ..moveTo(14, -31)
      ..quadraticBezierTo(27, -38, 36, -28)
      ..lineTo(38, -9)
      ..quadraticBezierTo(27, 0, 14, -8)
      ..close();
    fill(pouch, const Color(0xFFA96B3A));
    line(pouch, const Color(0xFF704728), 1.4);
    line(
      Path()
        ..moveTo(16, -24)
        ..quadraticBezierTo(27, -30, 36, -23),
      const Color(0xFFE4B56D),
      2,
    );
    flower(27, -18, 4.2, const Color(0xFFFFF2D2));
    // Arms move independently and wrap around the offered present.
    final reach = pose.gift;
    line(
      Path()
        ..moveTo(-23, -45)
        ..quadraticBezierTo(-29, -30, -16 + reach * 10, -24 + reach * 4),
      edge,
      11,
    );
    line(
      Path()
        ..moveTo(-23, -46)
        ..quadraticBezierTo(-29, -31, -16 + reach * 10, -25 + reach * 4),
      cream,
      9,
    );
    c.save();
    c.translate(23, -44);
    c.rotate(pose.waveAngle);
    c.translate(-23, 44);
    line(
      Path()
        ..moveTo(23, -44)
        ..quadraticBezierTo(30, -29, 16 + reach * 5, -23 + reach * 4),
      edge,
      11,
    );
    line(
      Path()
        ..moveTo(23, -45)
        ..quadraticBezierTo(30, -30, 16 + reach * 5, -24 + reach * 4),
      cream,
      9,
    );
    c.restore();
    if (pose.gift > 0) {
      c.save();
      c.translate(3, -29 + reach * 5);
      c.scale(.8 + reach * .2);
      fill(
        Path()
          ..moveTo(-20, -16)
          ..quadraticBezierTo(0, -19, 22, -16)
          ..lineTo(23, 11)
          ..quadraticBezierTo(1, 15, -20, 11)
          ..close(),
        const Color(0xFFE4BC79),
      );
      line(
        Path()
          ..moveTo(1, -17)
          ..lineTo(1, 12),
        const Color(0xFFB77F88),
        5,
      );
      line(
        Path()
          ..moveTo(-21, -14)
          ..lineTo(23, -14),
        const Color(0xFFF3D9A8),
        5,
      );
      line(
        Path()
          ..moveTo(1, -17)
          ..cubicTo(-22, -32, -9, -37, 1, -20)
          ..cubicTo(19, -38, 28, -31, 1, -17),
        const Color(0xFFB77F88),
        3,
      );
      oval(-20, 1, 9, 10, cream);
      oval(23, 0, 8, 10, cream);
      c.restore();
    }
    // Restrained fur marks, sharing the forest's warm printed-paper palette.
    for (final x in [-9.0, 3.0, 13.0]) {
      line(
        Path()
          ..moveTo(x, -10)
          ..lineTo(x + 1, -7),
        const Color(0x38C7B69C),
        .8,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_RabbitPainter old) =>
      old.mood != mood ||
      old.gift != gift ||
      old.quiet != quiet ||
      old.clock != clock ||
      old.action != action;
}

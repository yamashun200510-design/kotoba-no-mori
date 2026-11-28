import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'stage_areas.dart';
import 'stage_layout.dart';

/// Painted landscape used while an area's illustration is being prepared.
/// Everything is drawn in code (no external art) and the trail it draws is
/// the exact road the stage markers sit on.
class AreaScenePainter extends CustomPainter {
  final ForestArea area;
  final AreaLayout layout;
  final AreaPalette palette;

  /// When the area's scenery image is shown underneath, only the road (and,
  /// in riverside areas, the river it crosses) is drawn here.
  final bool roadOnly;
  AreaScenePainter(this.area, this.layout, {this.roadOnly = false})
    : palette = paletteFor(area);

  /// The painted part ends where the original illustration (area 1) begins.
  double get _paintedBottom => layout.height - layout.legacyHeight;

  /// Distance from [p] to the road (the trail is densely sampled).
  double _distanceToRoad(Offset p) {
    var best = double.infinity;
    final trail = layout.trail;
    for (var i = 0; i < trail.length; i += 2) {
      final d = (trail[i] - p).distanceSquared;
      if (d < best) best = d;
    }
    return math.sqrt(best);
  }

  bool get _riverside => area.road == RoadStyle.riverside;

  /// The river of riverside areas runs down the middle, between the banks
  /// the road follows.
  double _riverX(double y, double w) =>
      w * (.5 + .025 * math.sin(y / 170 + area.number));
  static const _riverHalfWidth = .12;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, bottom = _paintedBottom;
    final rng = math.Random(area.number * 7919);
    final fill = Paint()..isAntiAlias = true;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, bottom));
    if (roadOnly) {
      // The river stays app-drawn so the bridges always line up with it.
      if (_riverside) _river(canvas, w, bottom);
      _trail(canvas);
      canvas.restore();
      return;
    }
    // Ground with soft lighter bands so long maps do not look flat.
    fill.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [palette.ground, palette.groundShade, palette.ground],
      stops: const [0, .5, 1],
      tileMode: TileMode.mirror,
    ).createShader(Rect.fromLTWH(0, 0, w, 900));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, bottom), fill);
    fill.shader = null;

    _sky(canvas, w);
    if (_riverside) _river(canvas, w, bottom);
    if (area.theme == AreaTheme.seaside) _sea(canvas, w, bottom);
    _motifs(canvas, w, bottom, rng);
    _trail(canvas);
    if (area.season == AreaSeason.winter) _snowfall(canvas, w, bottom, rng);
    if (area.season == AreaSeason.autumn) _leaves(canvas, w, bottom, rng);
    canvas.restore();

    if (layout.legacyHeight > 0) {
      // Blend the painted road into the top of the original illustration.
      fill.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.ground.withValues(alpha: 0), palette.ground],
      ).createShader(Rect.fromLTWH(0, bottom - 60, w, 60));
      canvas.drawRect(Rect.fromLTWH(0, bottom - 60, w, 60), fill);
      fill.shader = null;
    }
  }

  void _sky(Canvas canvas, double w) {
    const h = 210.0;
    final paint = Paint();
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [palette.skyTop, palette.skyBottom, palette.ground],
      stops: const [0, .75, 1],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    paint.shader = null;

    // Sun, moon or a pale winter sun.
    final glow = switch (area.season) {
      AreaSeason.dusk => const Color(0xFFFF8A4C),
      AreaSeason.winter => const Color(0xFFFFFBEA),
      _ => const Color(0xFFFFF1A8),
    };
    final moon =
        area.theme == AreaTheme.river && area.season == AreaSeason.autumn;
    paint.color = moon ? const Color(0xFFFFF6CF) : glow;
    canvas.drawCircle(Offset(w * .78, 62), moon ? 22 : 28, paint);

    // Clouds.
    paint.color = Colors.white.withValues(
      alpha: area.season == AreaSeason.dusk ? .5 : .85,
    );
    for (final c in [Offset(w * .22, 48), Offset(w * .5, 84)]) {
      canvas.drawOval(Rect.fromCenter(center: c, width: 74, height: 24), paint);
      canvas.drawOval(
        Rect.fromCenter(center: c.translate(18, -9), width: 44, height: 24),
        paint,
      );
    }

    // Horizon silhouettes.
    final far = Paint()
      ..color = Color.lerp(palette.skyBottom, palette.foliageShade, .55)!;
    final path = Path()..moveTo(0, h - 30);
    switch (area.theme) {
      case AreaTheme.mountain || AreaTheme.snowfield:
        path
          ..lineTo(w * .18, h - 92)
          ..lineTo(w * .34, h - 46)
          ..lineTo(w * .55, h - 118)
          ..lineTo(w * .78, h - 52)
          ..lineTo(w * .92, h - 84)
          ..lineTo(w, h - 60);
      case AreaTheme.seaside:
        path.lineTo(w, h - 30);
      default:
        path
          ..quadraticBezierTo(w * .25, h - 70, w * .5, h - 40)
          ..quadraticBezierTo(w * .75, h - 12, w, h - 50);
    }
    path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, far);
    if (area.theme == AreaTheme.mountain ||
        area.theme == AreaTheme.snowfield ||
        area.season == AreaSeason.winter) {
      // Snowy peaks.
      final snow = Paint()..color = Colors.white.withValues(alpha: .9);
      canvas.drawPath(
        Path()
          ..moveTo(w * .55, h - 118)
          ..lineTo(w * .50, h - 100)
          ..lineTo(w * .60, h - 100)
          ..close(),
        snow,
      );
    }
    if (area.theme == AreaTheme.seaside) {
      canvas.drawRect(
        Rect.fromLTWH(0, h - 30, w, 30),
        Paint()..color = const Color(0xFF6CB7DA),
      );
    }
  }

  void _river(Canvas canvas, double w, double bottom) {
    // A river down the middle; the road follows one bank and crosses it on
    // bridges (drawn with the road).
    final path = Path();
    var first = true;
    for (var y = 200.0; y <= bottom; y += 6) {
      final x = _riverX(y, w);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * _riverHalfWidth * 2
        ..strokeCap = StrokeCap.round
        ..color = area.season == AreaSeason.winter
            ? const Color(0xFFA9C7D9)
            : const Color(0xFF79BEDF),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: .45),
    );
  }

  void _sea(Canvas canvas, double w, double bottom) {
    final rect = Rect.fromLTWH(0, 210, w * .26, bottom - 210);
    canvas.drawRect(
      rect,
      Paint()
        ..color = area.season == AreaSeason.winter
            ? const Color(0xFF7FA7C2)
            : const Color(0xFF5DB2D8),
    );
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withValues(alpha: .7);
    for (var y = 240.0; y < bottom; y += 46) {
      for (var x = 10.0; x < w * .24; x += 34) {
        canvas.drawArc(
          Rect.fromLTWH(x, y + (x % 3) * 6, 22, 12),
          math.pi,
          math.pi,
          false,
          wave,
        );
      }
    }
    // Foam line along the beach.
    canvas.drawRect(
      Rect.fromLTWH(w * .26 - 4, 210, 8, bottom - 210),
      Paint()..color = Colors.white.withValues(alpha: .8),
    );
  }

  void _motifs(Canvas canvas, double w, double bottom, math.Random rng) {
    final minX = area.theme == AreaTheme.seaside ? w * .30 : 18.0;
    for (var y = 240.0; y < bottom - 20; y += 46) {
      for (var n = 0; n < 3; n++) {
        final p = Offset(
          minX + rng.nextDouble() * (w - 18 - minX),
          y + rng.nextDouble() * 30,
        );
        if (_distanceToRoad(p) < 52) continue;
        if (_riverside && (p.dx - _riverX(p.dy, w)).abs() < w * .17) continue;
        if (area.road == RoadStyle.weave && rng.nextDouble() < .3) {
          _obstacle(canvas, p, rng);
        } else {
          _motif(canvas, p, rng);
        }
      }
    }
  }

  /// Houses, rocks and ponds the weaving road threads between.
  void _obstacle(Canvas canvas, Offset p, math.Random rng) {
    final paint = Paint()..isAntiAlias = true;
    switch (rng.nextInt(3)) {
      case 0:
        // A small farmhouse.
        paint.color = const Color(0xFFEDE0C8);
        canvas.drawRect(
          Rect.fromCenter(center: p, width: 30, height: 20),
          paint,
        );
        paint.color = area.season == AreaSeason.winter
            ? Colors.white
            : const Color(0xFF8C5A3C);
        canvas.drawPath(
          Path()
            ..moveTo(p.dx - 20, p.dy - 9)
            ..lineTo(p.dx, p.dy - 24)
            ..lineTo(p.dx + 20, p.dy - 9)
            ..close(),
          paint,
        );
        paint.color = const Color(0xFF6B4A33);
        canvas.drawRect(Rect.fromLTWH(p.dx - 4, p.dy - 2, 8, 12), paint);
      case 1:
        // Rocks.
        paint.color = const Color(0xFFA8A69C);
        canvas.drawOval(
          Rect.fromCenter(center: p, width: 30, height: 20),
          paint,
        );
        paint.color = const Color(0xFFC9C7BD);
        canvas.drawOval(
          Rect.fromCenter(center: p.translate(-9, 3), width: 18, height: 12),
          paint,
        );
      default:
        // A little pond.
        paint.color = area.season == AreaSeason.winter
            ? const Color(0xFFC9DCE8)
            : const Color(0xFF7FC3E3);
        canvas.drawOval(
          Rect.fromCenter(center: p, width: 38, height: 20),
          paint,
        );
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: .6);
        canvas.drawArc(
          Rect.fromCenter(center: p, width: 24, height: 10),
          math.pi,
          math.pi * .7,
          false,
          paint,
        );
    }
  }

  void _motif(Canvas canvas, Offset p, math.Random rng) {
    final paint = Paint()..isAntiAlias = true;
    final s = .8 + rng.nextDouble() * .5;
    switch (area.theme) {
      case AreaTheme.forest || AreaTheme.hill when rng.nextDouble() < .55:
        _tree(canvas, p, s, rng);
      case AreaTheme.mountain:
        _pine(canvas, p, s);
      case AreaTheme.snowfield:
        if (rng.nextBool()) {
          paint.color = Colors.white;
          canvas.drawOval(
            Rect.fromCenter(center: p, width: 56 * s, height: 20 * s),
            paint,
          );
          paint.color = palette.groundShade;
          canvas.drawOval(
            Rect.fromCenter(
              center: p.translate(0, 5 * s),
              width: 50 * s,
              height: 8 * s,
            ),
            paint,
          );
        } else {
          _bareTree(canvas, p, s);
        }
      case AreaTheme.paddy:
        final color = switch (area.season) {
          AreaSeason.spring => const Color(0xFF9FCFE0),
          AreaSeason.autumn => const Color(0xFFE6C15A),
          AreaSeason.winter => const Color(0xFFE2DED2),
          _ => const Color(0xFF6DB55A),
        };
        paint.color = color;
        final r = Rect.fromCenter(center: p, width: 50 * s, height: 30 * s);
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)),
          paint,
        );
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = palette.groundShade;
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)),
          paint,
        );
        if (area.season == AreaSeason.spring ||
            area.season == AreaSeason.summer) {
          paint
            ..style = PaintingStyle.fill
            ..color = const Color(0xFF4E9A52);
          for (var i = 0; i < 6; i++) {
            canvas.drawCircle(
              r.topLeft.translate(
                8 + (i % 3) * 16.0 * s,
                9 + (i ~/ 3) * 12.0 * s,
              ),
              2,
              paint,
            );
          }
        }
      case AreaTheme.seaside:
        if (rng.nextBool()) {
          _pine(canvas, p, s * .9);
        } else {
          paint.color = palette.accent;
          canvas.drawOval(
            Rect.fromCenter(center: p, width: 10, height: 7),
            paint,
          );
        }
      case AreaTheme.meadow ||
          AreaTheme.river ||
          AreaTheme.hill ||
          AreaTheme.forest:
        // Grass tufts with a few flowers.
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = palette.foliageShade;
        for (var i = -2; i <= 2; i++) {
          canvas.drawLine(
            p,
            p.translate(i * 5.0 * s, -16 * s + i.abs() * 3),
            paint,
          );
        }
        if (rng.nextDouble() < .6) {
          paint
            ..style = PaintingStyle.fill
            ..color = rng.nextBool() ? palette.accent : palette.accent2;
          canvas.drawCircle(p.translate(10 * s, -14 * s), 4.2 * s, paint);
          canvas.drawCircle(p.translate(-11 * s, -10 * s), 3.4 * s, paint);
        }
    }
  }

  void _tree(Canvas canvas, Offset p, double s, math.Random rng) {
    final paint = Paint()..color = const Color(0xFF8A6542);
    canvas.drawRect(
      Rect.fromCenter(
        center: p.translate(0, -6 * s),
        width: 7 * s,
        height: 20 * s,
      ),
      paint,
    );
    paint.color = palette.foliageShade;
    canvas.drawCircle(p.translate(-8 * s, -22 * s), 14 * s, paint);
    paint.color = palette.foliage;
    canvas.drawCircle(p.translate(6 * s, -26 * s), 15 * s, paint);
    canvas.drawCircle(p.translate(-2 * s, -36 * s), 12 * s, paint);
    if (area.season == AreaSeason.spring && rng.nextBool()) {
      paint.color = palette.accent;
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(
          p.translate((i * 7 - 14) * s, (-28 - (i % 2) * 8) * s),
          2.6 * s,
          paint,
        );
      }
    }
  }

  void _pine(Canvas canvas, Offset p, double s) {
    final paint = Paint()..color = const Color(0xFF7A5A3C);
    canvas.drawRect(
      Rect.fromCenter(
        center: p.translate(0, -4 * s),
        width: 6 * s,
        height: 12 * s,
      ),
      paint,
    );
    paint.color = area.season == AreaSeason.autumn
        ? const Color(0xFF3F7A4A)
        : palette.foliageShade;
    for (var i = 0; i < 3; i++) {
      final top = p.translate(0, (-46 + i * 12) * s);
      canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..lineTo(top.dx - (12 + i * 5) * s, top.dy + 18 * s)
          ..lineTo(top.dx + (12 + i * 5) * s, top.dy + 18 * s)
          ..close(),
        paint,
      );
    }
    if (area.season == AreaSeason.winter) {
      paint.color = Colors.white.withValues(alpha: .85);
      canvas.drawCircle(p.translate(0, -44 * s), 4 * s, paint);
    }
  }

  void _bareTree(Canvas canvas, Offset p, double s) {
    final paint = Paint()
      ..color = const Color(0xFF7E6A5A)
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p, p.translate(0, -36 * s), paint);
    paint.strokeWidth = 2 * s;
    canvas.drawLine(
      p.translate(0, -20 * s),
      p.translate(-12 * s, -32 * s),
      paint,
    );
    canvas.drawLine(
      p.translate(0, -26 * s),
      p.translate(11 * s, -38 * s),
      paint,
    );
  }

  void _trail(Canvas canvas) {
    final trail = layout.trail;
    if (trail.length < 2) return;
    final path = Path()..moveTo(trail.first.dx, trail.first.dy);
    for (final p in trail.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      path,
      stroke
        ..strokeWidth = 40
        ..color = palette.trailEdge,
    );
    canvas.drawPath(
      path,
      stroke
        ..strokeWidth = 33
        ..color = palette.trail,
    );
    switch (area.road) {
      case RoadStyle.stairs:
        _steps(canvas, trail);
      case RoadStyle.riverside:
        _bridges(canvas, trail);
      default:
        // A few pebbles along the center so the road reads as a path.
        final pebble = Paint()
          ..color = palette.trailEdge.withValues(alpha: .35);
        for (var i = 0; i < trail.length; i += 9) {
          final p = trail[i];
          canvas.drawCircle(p.translate(i.isEven ? 7 : -8, 0), 2, pebble);
        }
    }
  }

  /// Stone steps across the climbing parts of a stairs road.
  void _steps(Canvas canvas, List<Offset> trail) {
    final line = Paint()
      ..color = palette.trailEdge.withValues(alpha: .65)
      ..strokeWidth = 2;
    var since = 0.0;
    for (var i = 1; i < trail.length; i++) {
      final a = trail[i - 1], b = trail[i];
      final climbing = (b.dx - a.dx).abs() < .5;
      since += (b - a).distance;
      if (climbing && since >= 11) {
        since = 0;
        canvas.drawLine(b.translate(-15, 0), b.translate(15, 0), line);
      }
    }
  }

  /// Wooden bridges where a riverside road crosses the river.
  void _bridges(Canvas canvas, List<Offset> trail) {
    final w = layout.width;
    final plank = Paint()..color = const Color(0xFFB98552);
    final seam = Paint()
      ..color = const Color(0xFF7C5432)
      ..strokeWidth = 1.5;
    final rail = Paint()
      ..color = const Color(0xFF6E4A2C)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    var i = 1;
    while (i < trail.length) {
      if ((trail[i].dy - trail[i - 1].dy).abs() > .5) {
        i++;
        continue;
      }
      // A horizontal run: the bridge.
      final y = trail[i].dy;
      var j = i;
      while (j < trail.length && (trail[j].dy - y).abs() <= .5) {
        j++;
      }
      final xs = [trail[i - 1].dx, trail[j - 1].dx]..sort();
      final river = _riverX(y, w);
      final from = math.max(xs[0], river - w * (_riverHalfWidth + .03));
      final to = math.min(xs[1], river + w * (_riverHalfWidth + .03));
      if (to > from) {
        canvas.drawRect(Rect.fromLTRB(from, y - 17, to, y + 17), plank);
        for (var x = from + 6; x < to; x += 7) {
          canvas.drawLine(Offset(x, y - 17), Offset(x, y + 17), seam);
        }
        canvas.drawLine(Offset(from, y - 18), Offset(to, y - 18), rail);
        canvas.drawLine(Offset(from, y + 18), Offset(to, y + 18), rail);
      }
      i = j + 1;
    }
  }

  void _snowfall(Canvas canvas, double w, double bottom, math.Random rng) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .8);
    for (var i = 0; i < bottom / 14; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * bottom),
        1.4 + rng.nextDouble() * 1.6,
        paint,
      );
    }
  }

  void _leaves(Canvas canvas, double w, double bottom, math.Random rng) {
    final paint = Paint();
    for (var i = 0; i < bottom / 40; i++) {
      paint.color = (rng.nextBool() ? palette.accent : palette.accent2)
          .withValues(alpha: .8);
      canvas.save();
      canvas.translate(rng.nextDouble() * w, rng.nextDouble() * bottom);
      canvas.rotate(rng.nextDouble() * math.pi);
      canvas.drawOval(const Rect.fromLTWH(-4, -2.5, 8, 5), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(AreaScenePainter old) =>
      old.area != area ||
      old.layout.width != layout.width ||
      old.roadOnly != roadOnly;
}

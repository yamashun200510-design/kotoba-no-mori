import 'dart:math' as math;
import 'dart:ui';

import 'stage_areas.dart';

/// Original 花咲く小道 illustration (979x1606) used under stages 1-10.
const legacyMapAsset = 'assets/art/cartoon-map.png';
const legacyMapAspect = 1606 / 979;

/// Node centers on the visible centerline of cartoon-map.png, measured from
/// the artwork (2026-11-27). Stages 1 and 7 are fixed anchors; the rest sit at
/// equal arc-length intervals between them (see commit 7080baf).
const legacyAnchors = <Offset>[
  Offset(.51, .94),
  Offset(.467, .817),
  Offset(.580, .710),
  Offset(.602, .602),
  Offset(.555, .519),
  Offset(.620, .428),
  Offset(.69, .33),
  Offset(.602, .229),
  Offset(.717, .140),
  Offset(.596, .064),
];

/// Vertical room per stage on painted maps, and margins at both ends.
const stageSpacing = 96.0;
const mapTopPad = 104.0;
const mapBottomPad = 72.0;

class AreaLayout {
  final double width, height;

  /// Stage id → center of its marker, in map coordinates (y grows down).
  final Map<int, Offset> nodes;

  /// Centerline of the road drawn over the scenery.
  final List<Offset> trail;

  /// Height of the original illustration at the bottom of area 1 (else 0).
  final double legacyHeight;
  const AreaLayout({
    required this.width,
    required this.height,
    required this.nodes,
    required this.trail,
    this.legacyHeight = 0,
  });
}

/// Places every stage of [area] for a map [width] pixels wide. The first and
/// last stages sit at the ends of the road; the ones between are spread at
/// equal distances along its centerline.
AreaLayout layoutArea(ForestArea area, double width) {
  final first = area.firstStage, count = stagesPerArea;
  if (area.number == 1) {
    final legacy = width * legacyMapAspect;
    final painted = (count - legacyAnchors.length) * stageSpacing + mapTopPad;
    final nodes = <int, Offset>{
      for (var i = 0; i < legacyAnchors.length; i++)
        first + i: Offset(
          legacyAnchors[i].dx * width,
          painted + legacyAnchors[i].dy * legacy,
        ),
    };
    final trail = serpentine(
      nodes[first + legacyAnchors.length - 1]!,
      mapTopPad,
      width,
    );
    nodes.addAll(
      _spread(
        trail,
        first + legacyAnchors.length,
        count - legacyAnchors.length,
        includeStart: false,
      ),
    );
    return AreaLayout(
      width: width,
      height: painted + legacy,
      nodes: nodes,
      trail: trail,
      legacyHeight: legacy,
    );
  }
  final height = (count - 1) * stageSpacing + mapTopPad + mapBottomPad;
  final start = Offset(
    width * (area.number.isEven ? .42 : .58),
    height - mapBottomPad,
  );
  final trail = serpentine(start, mapTopPad, width, seed: area.number);
  return AreaLayout(
    width: width,
    height: height,
    nodes: _spread(trail, first, count, includeStart: true),
    trail: trail,
  );
}

/// A gently winding road from [start] up to the height [topY].
List<Offset> serpentine(
  Offset start,
  double topY,
  double width, {
  int seed = 0,
}) {
  const amplitude = .26, wavelength = 560.0;
  final s = ((start.dx / width - .5) / amplitude).clamp(-1.0, 1.0);
  final phase = math.asin(s);
  final turn = seed % 3 == 1 ? -1.0 : 1.0;
  final points = <Offset>[];
  for (var y = start.dy; y > topY; y -= 4) {
    final t = (start.dy - y) / wavelength * 2 * math.pi;
    final x = .5 + amplitude * math.sin(phase + turn * t);
    points.add(Offset(width * x, y));
  }
  final t = (start.dy - topY) / wavelength * 2 * math.pi;
  points.add(
    Offset(width * (.5 + amplitude * math.sin(phase + turn * t)), topY),
  );
  return points;
}

/// Spreads [count] stages along [road] at equal arc length. With
/// [includeStart] the first stage sits on the road's start; otherwise the
/// start is the previous stage and the first new stage is one step along.
/// The last stage always sits on the road's end.
Map<int, Offset> _spread(
  List<Offset> road,
  int firstId,
  int count, {
  required bool includeStart,
}) {
  final lengths = <double>[0];
  for (var i = 1; i < road.length; i++) {
    lengths.add(lengths.last + (road[i] - road[i - 1]).distance);
  }
  final total = lengths.last;
  final steps = includeStart ? count - 1 : count;
  Offset at(double d) {
    if (d <= 0) return road.first;
    if (d >= total) return road.last;
    var lo = 0, hi = lengths.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) ~/ 2;
      if (lengths[mid] <= d) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final span = lengths[hi] - lengths[lo];
    final f = span == 0 ? 0.0 : (d - lengths[lo]) / span;
    return Offset.lerp(road[lo], road[hi], f)!;
  }

  return {
    for (var k = 0; k < count; k++)
      firstId + k: at(total * (includeStart ? k : k + 1) / steps),
  };
}

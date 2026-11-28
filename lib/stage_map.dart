import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'press_feedback.dart';
import 'rabbit_mascot.dart';
import 'area_scene_painter.dart';
import 'stage_areas.dart';
import 'stage_journey.dart';
import 'stage_layout.dart';

class StageStars extends StatelessWidget {
  final int count;
  final bool animate;
  final double size;
  const StageStars({
    super.key,
    required this.count,
    this.animate = false,
    this.size = 24,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: '星$count / 3',
    child: ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animate ? 0 : 1, end: 1),
        duration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 800,
        ),
        builder: (context, t, child) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(0, i == 1 ? -5 : 0),
                child: Transform.scale(
                  scale: i < count
                      ? .8 +
                            .2 *
                                Curves.easeOutBack.transform(
                                  ((t - i * .14) / .72).clamp(0, 1),
                                )
                      : 1,
                  child: Icon(
                    i < count ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: size,
                    color: i < count
                        ? const Color(0xFFFFC62D)
                        : const Color(0xFF797C77),
                    shadows: [
                      Shadow(
                        color: i < count
                            ? const Color(0xFF9A682B)
                            : Colors.white,
                        offset: const Offset(0, 1),
                        blurRadius: animate ? math.sin(t * math.pi) * 9 : 0,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class ForestStageMap extends StatefulWidget {
  final StageJourney journey;
  final ValueChanged<int> onSelect;
  final VoidCallback onNormalModes;
  final bool reduceMotion;
  const ForestStageMap({
    super.key,
    required this.journey,
    required this.onSelect,
    required this.onNormalModes,
    this.reduceMotion = false,
  });
  @override
  State<ForestStageMap> createState() => _ForestStageMapState();
}

class _ForestStageMapState extends State<ForestStageMap>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final scroll = ScrollController();
  static const markerWidth = 68.0;
  static const markerHeight = 64.0;
  late final AnimationController ambience = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  );
  bool appActive = true;
  late int lastFrontier;

  /// The area shown; it follows the current stage unless the player browses.
  late ForestArea area;
  AreaLayout? _layout;

  AreaLayout layoutFor(double width) {
    final cached = _layout;
    if (cached != null &&
        cached.width == width &&
        cached.nodes.containsKey(area.firstStage)) {
      return cached;
    }
    return _layout = layoutArea(area, width);
  }

  int get areaCleared => [
    for (var id = area.firstStage; id <= area.lastStage; id++) id,
  ].where((id) => (widget.journey.stars[id] ?? 0) > 0).length;

  bool canOpen(ForestArea target) => widget.journey.unlocked(target.firstStage);

  void showArea(ForestArea target) {
    if (target == area || !canOpen(target)) return;
    setState(() {
      area = target;
      _layout = null;
    });
    revealFrontier();
  }

  /// Scrolls so the current stage is comfortably in view (or, in an area
  /// without it, to the area's start at the bottom).
  void revealFrontier() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scroll.hasClients) return;
      final width = context.size?.width ?? 0;
      if (width <= 0) return;
      final layout = layoutFor(width);
      final viewport = scroll.position.viewportDimension;
      final frontier = layout.nodes[widget.journey.frontier];
      final target = frontier == null
          ? scroll.position.maxScrollExtent
          : frontier.dy - viewport * .62;
      final safeTarget = target.clamp(0.0, scroll.position.maxScrollExtent);
      if ((scroll.position.pixels - safeTarget).abs() < 1) return;
      scroll.jumpTo(safeTarget);
    });
  }

  @override
  void initState() {
    super.initState();
    lastFrontier = widget.journey.frontier;
    area = areaOfStage(lastFrontier);
    WidgetsBinding.instance.addObserver(this);
    revealFrontier();
  }

  void syncAmbience() {
    final enabled =
        appActive &&
        area.number == 1 &&
        !widget.reduceMotion &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled && !ambience.isAnimating) {
      ambience.repeat();
    } else if (!enabled && ambience.isAnimating) {
      ambience.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncAmbience();
  }

  @override
  void didUpdateWidget(ForestStageMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncAmbience();
    if (lastFrontier != widget.journey.frontier) {
      lastFrontier = widget.journey.frontier;
      final next = areaOfStage(lastFrontier);
      if (next != area) {
        area = next;
        _layout = null;
      }
      revealFrontier();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appActive = state == AppLifecycleState.resumed;
    if (mounted) syncAmbience();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ambience.dispose();
    scroll.dispose();
    super.dispose();
  }

  void explain() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('小道の星を集めよう'),
      content: const Text(
        '3回以内で正解：星3つ\n6回以内で正解：星2つ\n7回以上でも正解：星1つ\n\n何度でも挑戦できます。いちばん良い星が残ります。\nステージでは星を集めます。コインや今日の目標は通常モードで楽しめます。',
        style: TextStyle(fontSize: 19, height: 1.5),
      ),
      scrollable: true,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('とじる'),
        ),
      ],
    ),
  );

  Widget areaArrow({required bool next}) {
    final index = area.number - 1 + (next ? 1 : -1);
    final target = index >= 0 && index < forestAreas.length
        ? forestAreas[index]
        : null;
    final enabled = target != null && canOpen(target);
    return IconButton(
      key: ValueKey(next ? 'area-next' : 'area-previous'),
      tooltip: target == null
          ? null
          : enabled
          ? '${next ? '次' : '前'}のエリア「${target.name}」へ'
          : '前のエリアをすべてクリアすると進めます',
      onPressed: enabled ? () => showArea(target) : null,
      icon: Icon(next ? Icons.chevron_right : Icons.chevron_left, size: 30),
      color: const Color(0xFF28543C),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final cleared = areaCleared;
    final allCleared = cleared == stagesPerArea;
    final nextArea = area.number < forestAreas.length
        ? forestAreas[area.number]
        : null;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          padding: const EdgeInsets.fromLTRB(8, 2, 6, 2),
          decoration: BoxDecoration(
            color: const Color(0xF5FFF9E7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD6BD86)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  RabbitMascot(
                    width: 34,
                    height: 44,
                    animateIdle: false,
                    mood: widget.journey.cleared > 0
                        ? RabbitMood.happy
                        : RabbitMood.greeting,
                    event: widget.journey.frontier,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        area.name,
                        key: const ValueKey('stage-area-name'),
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: 'ZenMaru',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF28543C),
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 112),
                    child: TextButton(
                      key: const ValueKey('stage-star-help'),
                      onPressed: explain,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(48, 44),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 20,
                              color: Color(0xFFE0A526),
                            ),
                            SizedBox(width: 2),
                            Text(
                              '星の見かた',
                              maxLines: 1,
                              style: TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  areaArrow(next: false),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        narrow
                            ? 'エリア${area.number}／${forestAreas.length}・$cleared/$stagesPerArea クリア'
                            : 'エリア${area.number}／${forestAreas.length}・$cleared / $stagesPerArea ステージをクリア',
                        key: const ValueKey('stage-progress'),
                        maxLines: 1,
                        style: const TextStyle(fontSize: 16, height: 1.2),
                      ),
                    ),
                  ),
                  areaArrow(next: true),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final layout = layoutFor(bounds.maxWidth);
              // The map shrinks with the screen, so the markers shrink with
              // it: otherwise close stages overlap on narrow phones.
              final markerScale = (bounds.maxWidth / 400).clamp(.82, 1.0);
              final painted = layout.height - layout.legacyHeight;
              return SingleChildScrollView(
                key: const ValueKey('stage-map-scroll'),
                controller: scroll,
                child: SizedBox(
                  key: ValueKey('stage-area-map-${area.number}'),
                  height: layout.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (area.image != null)
                        // Road-free scenery repeated down the map.
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          height: layout.height - layout.legacyHeight,
                          child: ExcludeSemantics(
                            child: IgnorePointer(
                              child: Image.asset(
                                area.image!,
                                fit: BoxFit.fitWidth,
                                repeat: ImageRepeat.repeatY,
                                alignment: Alignment.topCenter,
                                cacheWidth: 1080,
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: ExcludeSemantics(
                          child: IgnorePointer(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: AreaScenePainter(
                                  area,
                                  layout,
                                  roadOnly: area.image != null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (layout.legacyHeight > 0) ...[
                        // The original 花咲く小道 illustration under stages
                        // 1-10; its anchors keep their measured positions.
                        Positioned(
                          left: 0,
                          right: 0,
                          top: painted,
                          height: layout.legacyHeight,
                          child: ExcludeSemantics(
                            child: IgnorePointer(
                              child: Image.asset(
                                legacyMapAsset,
                                fit: BoxFit.fill,
                                cacheWidth: 1000,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: painted,
                          height: layout.legacyHeight,
                          child: IgnorePointer(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: _MapAmbiencePainter(ambience),
                              ),
                            ),
                          ),
                        ),
                        // Soft seam where the painted road continues upward.
                        Positioned(
                          left: 0,
                          right: 0,
                          top: painted - 1,
                          height: 40,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    paletteFor(area).ground,
                                    paletteFor(
                                      area,
                                    ).ground.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (allCleared)
                        Positioned(
                          top: 26,
                          left: 12,
                          right: 12,
                          child: Text(
                            nextArea == null
                                ? '1,000ステージ踏破！ また遊びにきてね'
                                : 'このエリアを踏破！ 次は「${nextArea.name}」へ',
                            key: const ValueKey('stage-area-complete'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Color(0xFF28543C),
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.white, blurRadius: 6),
                              ],
                            ),
                          ),
                        ),
                      for (final entry in layout.nodes.entries)
                        Positioned(
                          left: (entry.value.dx - markerWidth / 2).clamp(
                            0.0,
                            bounds.maxWidth - markerWidth,
                          ),
                          top: entry.value.dy - 32,
                          width: markerWidth,
                          height: markerHeight,
                          child: Transform.scale(
                            scale: markerScale,
                            child: _StageButton(
                              stage: forestStages[entry.key - 1],
                              stars: widget.journey.stars[entry.key] ?? 0,
                              current: entry.key == widget.journey.frontier,
                              unlocked: widget.journey.unlocked(entry.key),
                              animateStars:
                                  entry.key ==
                                  (widget.journey.cleared == forestStages.length
                                      ? forestStages.length
                                      : widget.journey.frontier - 1),
                              onPressed: () => widget.onSelect(entry.key),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onNormalModes,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xF5FFF9E7),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('3文字・4文字・5文字をえらぶ', maxLines: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small, transparent effects share normalized coordinates with the single
/// map illustration, so they travel with it while the player scrolls.
class _MapAmbiencePainter extends CustomPainter {
  final Animation<double> clock;
  _MapAmbiencePainter(this.clock) : super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    Offset point(double x, double y) => Offset(x * size.width, y * size.height);

    // Fine streams move down the waterfall and stay inside its blue area.
    for (var i = 0; i < 7; i++) {
      final travel = (t * .42 + i / 7) % 1;
      final y = .105 + travel * .225;
      final x = .305 + (i % 4) * .026 + math.sin(t * math.pi * 2 + i) * .006;
      final start = point(x, y);
      final middle = point(x + .004, y + .026);
      final end = point(x, y + .038);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(middle.dx, middle.dy, end.dx, end.dy);
      paint
        ..color = const Color(0xB8E8FBFF).withValues(alpha: .33)
        ..strokeWidth = math.max(1.2, size.width * .0022);
      canvas.drawPath(path, paint);
    }

    // Gentle glints and ripples on the pools below the falls and bridge.
    for (var i = 0; i < 5; i++) {
      final phase = (t + i * .19) % 1;
      paint
        ..color = Colors.white.withValues(
          alpha: .34 + .18 * math.sin(phase * math.pi),
        )
        ..strokeWidth = math.max(1.4, size.width * .0026);
      for (final pool in [
        (x: .35 + phase * .16, y: .385 + (i % 2) * .018, w: .032, h: .008),
        (
          x: .70 + ((phase + .45) % 1) * .17,
          y: .525 + (i % 2) * .012,
          w: .026,
          h: .006,
        ),
      ]) {
        canvas.drawArc(
          Rect.fromCenter(
            center: point(pool.x, pool.y),
            width: size.width * pool.w,
            height: size.height * pool.h,
          ),
          math.pi,
          math.pi,
          false,
          paint,
        );
      }
    }

    // Sky highlights drift at a barely noticeable pace.
    paint.style = PaintingStyle.fill;
    for (var i = 0; i < 3; i++) {
      final x = (.42 + i * .18 + t * .035) % 1.12 - .06;
      paint.color = Colors.white.withValues(alpha: .17);
      canvas.drawOval(
        Rect.fromCenter(
          center: point(x, .035 + i * .018),
          width: size.width * .065,
          height: size.height * .018,
        ),
        paint,
      );
    }

    // A few visible leaf tips sway without moving or deforming the artwork.
    for (var i = 0; i < 8; i++) {
      final x = i.isEven ? .07 + (i % 4) * .052 : .79 + (i % 4) * .047;
      final y = .18 + (i % 3) * .075;
      canvas.save();
      canvas.translate(size.width * x, size.height * y);
      canvas.rotate(math.sin(t * math.pi * 2 + i * 1.7) * .28);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(
          -size.width * .012,
          -size.height * .009,
          0,
          -size.height * .019,
        )
        ..quadraticBezierTo(size.width * .013, -size.height * .009, 0, 0)
        ..close();
      paint.color = const Color(0xFFB5D969).withValues(alpha: .72);
      canvas.drawPath(leaf, paint);
      canvas.restore();
    }

    // Three slow petals drift near the banks; no full-screen particle wash.
    for (var i = 0; i < 3; i++) {
      final phase = (t * .72 + i / 3) % 1;
      final x = .22 + i * .27 + math.sin(phase * math.pi * 2 + i) * .018;
      final y = .22 + phase * .40;
      paint.color =
          (i.isEven ? const Color(0xFFF5A8B5) : const Color(0xFFFFD875))
              .withValues(alpha: .8);
      canvas.save();
      canvas.translate(size.width * x, size.height * y);
      canvas.rotate(phase * math.pi * 2);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * .009,
          height: size.height * .006,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MapAmbiencePainter oldDelegate) =>
      oldDelegate.clock != clock;
}

class _StageButton extends StatelessWidget {
  final ForestStage stage;
  final int stars;
  final bool current, unlocked;
  final bool animateStars;
  final VoidCallback onPressed;
  const _StageButton({
    required this.stage,
    required this.stars,
    required this.current,
    required this.unlocked,
    required this.onPressed,
    this.animateStars = false,
  });
  @override
  Widget build(BuildContext context) {
    final palette = const [
      Color(0xFF7368EB),
      Color(0xFF7268E8),
      Color(0xFF7469E8),
      Color(0xFF7569E7),
    ];
    final color = unlocked
        ? palette[(stage.id - 1) % palette.length]
        : const Color(0xFF9FA9AB);
    return SizedBox(
      width: _ForestStageMapState.markerWidth,
      height: _ForestStageMapState.markerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (unlocked && stars > 0)
            Positioned(
              // Earned stars sit just above the marker and remain unobscured
              // by the circular stage button.
              top: -10,
              left: 7,
              child: StageStars(
                count: stars,
                animate: stars > 0 && animateStars,
                size: 18,
              ),
            ),
          Positioned(
            top: 8,
            left: 10,
            child: Semantics(
              label:
                  'ステージ${stage.id}、${unlocked
                      ? current
                            ? '挑戦できます'
                            : '再挑戦できます'
                      : 'まだ開いていません'}',
              child: PressFeedback(
                enabled: unlocked,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      const BoxShadow(
                        color: Color(0xFFD79822),
                        offset: Offset(0, 7),
                      ),
                      BoxShadow(
                        color: const Color(0xFF4C563A).withValues(alpha: .28),
                        blurRadius: 7,
                        offset: const Offset(0, 8),
                      ),
                      if (current)
                        const BoxShadow(
                          color: Color(0xAAFFF1AC),
                          blurRadius: 24,
                          spreadRadius: 9,
                        ),
                    ],
                  ),
                  child: ElevatedButton(
                    key: ValueKey('stage-${stage.id}'),
                    onPressed: unlocked ? onPressed : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      disabledBackgroundColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: const CircleBorder(),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: current
                              ? const Color(0xFFFFE5A0)
                              : const Color(0xFFFFF4D8),
                          width: current ? 5 : 4,
                        ),
                        gradient: RadialGradient(
                          center: const Alignment(-.35, -.55),
                          radius: 1.3,
                          colors: [
                            Color.lerp(color, Colors.white, .6)!,
                            color,
                            Color.lerp(color, const Color(0xFF665039), .45)!,
                          ],
                        ),
                      ),
                      child: SizedBox.expand(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 6,
                              left: 12,
                              right: 12,
                              height: 7,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white.withValues(alpha: .44),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${stage.id}',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xFF403595),
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (!unlocked)
                              const Positioned(
                                bottom: 1,
                                child: Icon(
                                  Icons.lock_rounded,
                                  size: 11,
                                  color: Color(0xFF4E5F4A),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

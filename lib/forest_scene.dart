import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'game.dart';
import 'rabbit_mascot.dart';

enum ForestSeason { spring, summer, autumn, winter }

enum ForestTime { morning, day, evening, night }

/// A forest scene is an area-sized canvas. Positions stored for decorations
/// are normalized within this canvas, so zooming/resizing never changes them.
@immutable
class ForestArea {
  final String id;
  final String name;
  final String backgroundAsset;
  final double aspectRatio;

  const ForestArea({
    required this.id,
    required this.name,
    required this.backgroundAsset,
    this.aspectRatio = 1.32,
  });
}

const firstForestArea = ForestArea(
  id: firstForestAreaId,
  name: '花と苗木の庭',
  backgroundAsset: 'assets/art/forest-garden.png',
);

/// Add future area definitions here; each area keeps its own canvas and save.
const forestAreaCatalog = <ForestArea>[firstForestArea];

ForestTime timeForHour(int hour) => hour >= 5 && hour < 10
    ? ForestTime.morning
    : hour >= 10 && hour < 16
    ? ForestTime.day
    : hour >= 16 && hour < 19
    ? ForestTime.evening
    : ForestTime.night;

ForestSeason seasonForMonth(int month) => month >= 3 && month <= 5
    ? ForestSeason.spring
    : month >= 6 && month <= 8
    ? ForestSeason.summer
    : month >= 9 && month <= 11
    ? ForestSeason.autumn
    : ForestSeason.winter;

/// Original, layered picture-book illustration. Canvas repaints independently
/// of the app; no image downloads, particles, filters or per-frame widget builds.
class ForestScene extends StatefulWidget {
  final int growth;
  final bool preview;
  final bool animate;
  final Set<String> items;
  final bool showRabbit;
  final bool homePalette;
  final bool foregroundOnly;
  final bool editable;
  final String? movingItem;

  /// When supplied, shows the player's unlocked garden friends.
  final Set<String>? friends;
  final Map<String, List<double>> itemPositions;
  final Map<String, ForestItemAppearance> itemAppearances;
  final void Function(String item, double x, double y)? onItemMoved;
  final ValueChanged<String>? onItemTapped;
  final int? month;
  final int? hour;
  final ForestArea area;
  const ForestScene({
    super.key,
    this.growth = 0,
    this.preview = false,
    this.animate = true,
    this.items = const {},
    this.showRabbit = true,
    this.homePalette = false,
    this.foregroundOnly = false,
    this.editable = false,
    this.movingItem,
    this.friends,
    this.itemPositions = const {},
    this.itemAppearances = const {},
    this.onItemMoved,
    this.onItemTapped,
    this.month,
    this.hour,
    this.area = firstForestArea,
  });
  static String stage(int n) => n < 1
      ? 'はじまりの芽'
      : n < 3
      ? '花と苗木の庭'
      : n < 6
      ? 'うさぎの花畑'
      : n < 8
      ? '蝶が舞う木立'
      : '森の仲間の楽園';
  @override
  State<ForestScene> createState() => _ForestSceneState();
}

class _ForestSceneState extends State<ForestScene>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final editTargetKey = GlobalKey();
  final Map<String, int> placementRevisions = {};
  Map<String, List<double>> observedPositions = {};
  ScrollPosition? scroll;
  Timer? clock;
  bool visible = true;
  bool active = true;
  DateTime now = DateTime.now();
  String? friendMessage;
  Offset? friendMessageAt;
  Timer? friendMessageTimer;
  @override
  void initState() {
    super.initState();
    observedPositions = _copyPositions(widget.itemPositions);
    WidgetsBinding.instance.addObserver(this);
    active =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void checkVisibility() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    final bounds = viewport is RenderBox && viewport.hasSize
        ? viewport.localToGlobal(Offset.zero) & viewport.size
        : Offset.zero &
              (View.of(context).physicalSize /
                  View.of(context).devicePixelRatio);
    final next = rect.overlaps(bounds);
    if (next != visible) {
      visible = next;
      syncMotion();
    }
  }

  void refreshClock() {
    if (!mounted) return;
    final next = DateTime.now();
    if (next.hour != now.hour || next.month != now.month) {
      setState(() => now = next);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (active) refreshClock();
    syncMotion();
  }

  late final AnimationController breeze = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );
  late final AnimationController bloom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
    value: 1,
  );
  bool quiet = true;
  bool introduced = false;
  Set<String> paintedItems = {};
  void syncMotion() {
    final next =
        !widget.animate ||
        !visible ||
        !active ||
        MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled;
    quiet = next;
    clock?.cancel();
    clock = widget.hour == null && visible && active
        ? Timer.periodic(const Duration(minutes: 1), (_) => refreshClock())
        : null;
    if (next) {
      breeze.stop();
      bloom.stop();
      bloom.value = 1;
    } else {
      if (!breeze.isAnimating) {
        breeze.repeat();
      }
      if (!introduced) {
        introduced = true;
        bloom.forward(from: 0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextScroll = Scrollable.maybeOf(context)?.position;
    if (scroll != nextScroll) {
      scroll?.removeListener(checkVisibility);
      scroll = nextScroll;
      scroll?.addListener(checkVisibility);
    }
    syncMotion();
    WidgetsBinding.instance.addPostFrameCallback((_) => checkVisibility());
  }

  @override
  void didUpdateWidget(ForestScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final entry in widget.itemPositions.entries) {
      final previous = observedPositions[entry.key];
      final next = entry.value;
      if (next.length == 2 &&
          (previous == null ||
              previous.length != 2 ||
              previous[0] != next[0] ||
              previous[1] != next[1])) {
        placementRevisions.update(
          entry.key,
          (revision) => revision + 1,
          ifAbsent: () => 1,
        );
      }
    }
    observedPositions = _copyPositions(widget.itemPositions);
    syncMotion();
    if (!quiet &&
        (widget.growth > oldWidget.growth ||
            widget.items.any((id) => !paintedItems.contains(id)))) {
      bloom.forward(from: 0);
    }
  }

  Map<String, List<double>> _copyPositions(Map<String, List<double>> source) =>
      {for (final entry in source.entries) entry.key: List.of(entry.value)};

  @override
  void dispose() {
    clock?.cancel();
    friendMessageTimer?.cancel();
    scroll?.removeListener(checkVisibility);
    WidgetsBinding.instance.removeObserver(this);
    breeze.dispose();
    bloom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.preview ? 10 : widget.growth;
    final season = seasonForMonth(widget.month ?? now.month);
    final daylight = timeForHour(widget.hour ?? now.hour);
    final backgroundTint = switch (daylight) {
      ForestTime.morning => const Color(0x16FFE8BC),
      ForestTime.day => switch (season) {
        ForestSeason.spring => const Color(0x0DE8D6C8),
        ForestSeason.summer => const Color(0x0D6DA858),
        ForestSeason.autumn => const Color(0x18ECA45B),
        ForestSeason.winter => const Color(0x1CC9E5F2),
      },
      ForestTime.evening => const Color(0x22E99063),
      ForestTime.night => const Color(0x35435478),
    };
    paintedItems = {...widget.items};
    return Semantics(
      label:
          '${const ['春', '夏', '秋', '冬'][season.index]}の${const ['朝', '昼', '夕方', '夜'][daylight.index]}。${ForestScene.stage(n)}。$n問の正解で育った森。お店の仲間${widget.items.length}種類',
      child: RepaintBoundary(
        child: AspectRatio(
          aspectRatio: widget.area.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  widget.area.backgroundAsset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
                ColoredBox(color: backgroundTint),
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _Woodland(
                      n,
                      widget.editable ? const <String>{} : paintedItems,
                      breeze,
                      bloom,
                      widget.showRabbit,
                      season,
                      daylight,
                      widget.homePalette,
                      true,
                      widget.friends,
                    ),
                  ),
                ),
                if (widget.friends != null)
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final size = Size(bounds.maxWidth, bounds.maxHeight);
                        return Stack(
                          children: [
                            for (final id in widget.friends!)
                              if (_friendAnchor(id) case final anchor?)
                                Positioned(
                                  left: anchor.dx / 420 * size.width - 26,
                                  top: anchor.dy / 320 * size.height - 48,
                                  width: 52,
                                  height: 58,
                                  child: Semantics(
                                    button: true,
                                    label: '${_friendName(id)}に話しかける',
                                    child: GestureDetector(
                                      key: ValueKey('forest-friend-$id'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () =>
                                          _showFriendMessage(id, anchor),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                ),
                            if (friendMessage != null &&
                                friendMessageAt != null)
                              Positioned(
                                left:
                                    (friendMessageAt!.dx / 420 * size.width -
                                            82)
                                        .clamp(4.0, size.width - 168),
                                top:
                                    (friendMessageAt!.dy / 320 * size.height -
                                            88)
                                        .clamp(4.0, size.height - 56),
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFDF3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFB88B5D),
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x3343311F),
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 9,
                                      ),
                                      child: Text(
                                        friendMessage!,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF513B2B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                if (widget.editable)
                  Positioned.fill(
                    child: DragTarget<String>(
                      key: editTargetKey,
                      onWillAcceptWithDetails: (details) =>
                          widget.items.contains(details.data) &&
                          (widget.movingItem == null
                              ? !widget.itemPositions.containsKey(details.data)
                              : widget.movingItem == details.data),
                      onAcceptWithDetails: (details) {
                        final renderBox = editTargetKey.currentContext
                            ?.findRenderObject();
                        if (renderBox is! RenderBox ||
                            widget.onItemMoved == null) {
                          return;
                        }
                        final local = renderBox.globalToLocal(details.offset);
                        final art = _artSize(details.data, renderBox.size);
                        // DragTarget reports the feedback's top-left position;
                        // restore the item's center and ground anchor.
                        final x =
                            ((local.dx + art.width / 2) / renderBox.size.width)
                                .clamp(
                                  art.width / renderBox.size.width / 2,
                                  1 - art.width / renderBox.size.width / 2,
                                );
                        final y =
                            ((local.dy + art.height) / renderBox.size.height)
                                .clamp(art.height / renderBox.size.height, 1.0);
                        widget.onItemMoved!(details.data, x, y);
                      },
                      builder: (context, candidates, rejected) => LayoutBuilder(
                        builder: (context, bounds) {
                          final size = Size(bounds.maxWidth, bounds.maxHeight);
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (final entry in widget.itemPositions.entries)
                                if (widget.items.contains(entry.key) &&
                                    entry.value.length == 2)
                                  _placedDecoration(
                                    entry,
                                    size,
                                    placementRevisions[entry.key] ?? 0,
                                  ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Offset? _friendAnchor(String id) => switch (id) {
    'rabbit' => const Offset(310, 274),
    'squirrel' => const Offset(122, 238),
    'hedgehog' => const Offset(354, 250),
    'tanuki' => const Offset(68, 204),
    'fawn' => const Offset(333, 193),
    _ => null,
  };

  String _friendName(String id) => switch (id) {
    'rabbit' => 'うさぎ',
    'squirrel' => 'りす',
    'hedgehog' => 'はりねずみ',
    'tanuki' => 'たぬき',
    'fawn' => 'こじか',
    _ => 'おともだち',
  };

  String _friendLine(String id) => switch (id) {
    'rabbit' => 'いっしょにあそぼう！',
    'squirrel' => '木の実を見つけたよ！',
    'hedgehog' => 'ゆっくりおさんぽ中。',
    'tanuki' => '森はにぎやかだね！',
    'fawn' => 'お花がきれいだね。',
    _ => 'こんにちは！',
  };

  void _showFriendMessage(String id, Offset anchor) {
    friendMessageTimer?.cancel();
    setState(() {
      friendMessage = _friendLine(id);
      friendMessageAt = anchor;
    });
    friendMessageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          friendMessage = null;
          friendMessageAt = null;
        });
      }
    });
  }

  Size _artSize(String id, Size sceneSize) {
    final logical = switch (id) {
      'cherry' => const Size(92, 112),
      'butterfly' => const Size(68, 58),
      _ => const Size(64, 76),
    };
    return Size(
      logical.width * sceneSize.width / 420,
      logical.height * sceneSize.height / 320,
    );
  }

  Widget _placedDecoration(
    MapEntry<String, List<double>> entry,
    Size sceneSize,
    int placementRevision,
  ) {
    final id = entry.key;
    final x = entry.value[0];
    final y = entry.value[1];
    final size = _artSize(id, sceneSize);
    final matchingItems = forestItems.where((item) => item.id == id);
    final title = matchingItems.isEmpty ? id : matchingItems.first.name;
    final appearance =
        widget.itemAppearances[id] ?? const ForestItemAppearance();
    Widget styledArt() {
      Widget art = ForestItemArt(
        item: id,
        width: size.width,
        height: size.height,
      );
      final tint = appearance.tint;
      if (tint != null && (id == 'tulip' || id == 'sunflower')) {
        art = ColorFiltered(
          colorFilter: ColorFilter.mode(
            Color(tint).withValues(alpha: .28),
            BlendMode.srcATop,
          ),
          child: art,
        );
      }
      return Transform.rotate(
        angle: appearance.safeRotationSteps * math.pi / 12,
        alignment: Alignment.bottomCenter,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            appearance.flipped ? -appearance.safeScale : appearance.safeScale,
            appearance.safeScale,
            1,
          ),
          child: art,
        ),
      );
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutBack,
      left: x * sceneSize.width - size.width / 2,
      top: y * sceneSize.height - size.height,
      width: size.width,
      height: size.height,
      child: _PlacementBounce(
        revision: placementRevision,
        child: AnimatedBuilder(
          animation: breeze,
          child: Semantics(
            label: widget.movingItem == id
                ? '$title。置きたい場所をタップしたまま動かしてください'
                : '$title。タップして操作',
            button: true,
            child: widget.movingItem == id
                ? Draggable<String>(
                    key: ValueKey('placed-forest-item-$id'),
                    data: id,
                    maxSimultaneousDrags: 1,
                    feedback: Material(
                      color: Colors.transparent,
                      child: styledArt(),
                    ),
                    childWhenDragging: Opacity(opacity: .3, child: styledArt()),
                    child: styledArt(),
                  )
                : GestureDetector(
                    key: ValueKey('placed-forest-item-$id'),
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.movingItem == null
                        ? () => widget.onItemTapped?.call(id)
                        : null,
                    child: styledArt(),
                  ),
          ),
          builder: (context, child) => Transform.rotate(
            angle:
                math.sin(
                  breeze.value * math.pi * 2 +
                      forestItems.indexOf(matchingItems.first) * .9,
                ) *
                .035,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PlacementBounce extends StatefulWidget {
  final int revision;
  final Widget child;
  const _PlacementBounce({required this.revision, required this.child});

  @override
  State<_PlacementBounce> createState() => _PlacementBounceState();
}

class _PlacementBounceState extends State<_PlacementBounce>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: widget.revision == 0 ? 1 : 0,
  );
  late final scale = Tween<double>(
    begin: .78,
    end: 1,
  ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    if (widget.revision > 0) controller.forward();
  }

  @override
  void didUpdateWidget(_PlacementBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revision != oldWidget.revision) controller.forward(from: 0);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: scale, child: widget.child);
}

class RabbitGiftArt extends StatelessWidget {
  const RabbitGiftArt({super.key});
  @override
  Widget build(BuildContext context) => const RabbitMascot(
    mood: RabbitMood.present,
    width: 76,
    height: 96,
    interactive: false,
  );
}

class ShopAwning extends StatelessWidget {
  const ShopAwning({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 48,
    width: double.infinity,
    child: CustomPaint(painter: _AwningPaint()),
  );
}

class _AwningPaint extends CustomPainter {
  const _AwningPaint();
  @override
  void paint(Canvas canvas, Size size) {
    final brush = Paint()..isAntiAlias = true;
    final width = size.width / 8;
    canvas.drawRect(
      Rect.fromLTWH(0, 4, size.width, 38),
      brush..color = const Color(0x24987558),
    );
    for (var i = 0; i < 8; i++) {
      final x = i * width;
      canvas.drawPath(
        Path()
          ..moveTo(x + 4, 0)
          ..lineTo(x + width - 4, 0)
          ..lineTo(x + width, 28)
          ..quadraticBezierTo(x + width / 2, 47, x, 28)
          ..close(),
        brush
          ..color = i.isEven
              ? const Color(0xFF77947A)
              : const Color(0xFFF5DFB6),
      );
      canvas.drawLine(
        Offset(x + 5, 3),
        Offset(x + 2, 25),
        brush
          ..color = const Color(0x40FFF8E4)
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_AwningPaint oldDelegate) => false;
}

class ForestItemArt extends StatelessWidget {
  final String item;
  final double width, height;
  const ForestItemArt({
    super.key,
    required this.item,
    this.width = 64,
    this.height = 76,
  });
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _ItemArt(item)),
    ),
  );
}

class _ItemArt extends _Woodland {
  final String item;
  _ItemArt(this.item)
    : super(
        0,
        {item},
        const AlwaysStoppedAnimation(0),
        const AlwaysStoppedAnimation(1),
      );
  @override
  void paint(Canvas canvas, Size size) {
    c = canvas;
    time = 0;
    c.save();
    c.translate(size.width / 2, size.height - 5);
    c.scale(math.min(size.width / 64, size.height / 76));
    if (item == 'cherry') {
      tree(0, 0, .38, 1);
    } else {
      final origin = switch (item) {
        'tulip' => const Offset(127, 305),
        'mushroom' => const Offset(345, 315),
        'sunflower' => const Offset(259, 305),
        _ => const Offset(94, 140),
      };
      c.translate(-origin.dx, -origin.dy);
      oval(0, 2, 42, 8, const Color(0x33415E3B));
      shopPlants();
    }
    c.restore();
  }
}

class _Woodland extends CustomPainter {
  final int growth;
  final Set<String> items;
  final bool showRabbit;
  final ForestSeason season;
  final ForestTime daylight;
  final bool homePalette;
  final bool foregroundOnly;
  final Set<String>? friends;
  final Animation<double> breeze;
  final Animation<double> bloom;
  _Woodland(
    this.growth,
    this.items,
    this.breeze,
    this.bloom, [
    this.showRabbit = true,
    this.season = ForestSeason.summer,
    this.daylight = ForestTime.day,
    this.homePalette = false,
    this.foregroundOnly = false,
    this.friends,
  ]) : super(repaint: Listenable.merge([breeze, bloom]));
  static const ink = Color(0xFF455343);
  static const bark = Color(0xFF937353);
  final brush = Paint()..isAntiAlias = true;
  late Canvas c;
  late double time;

  // Shared breeze, independent local rhythms. Integer harmonics join smoothly
  // across the 14-second controller loop, with one soft gust per cycle.
  double wind(double seed, {double strength = 1}) {
    final phase = seed * .071;
    final speed = 1 + (seed.abs().round() % 2);
    final gust = math.pow((1 - math.cos(time - .8)) / 2, 3).toDouble();
    return (math.sin(time * speed + phase) * .72 +
            math.sin(time * (speed + 1) + phase * .63) * .28) *
        (.6 + gust * .65) *
        strength;
  }

  void oval(double x, double y, double w, double h, Color color) => c.drawOval(
    Rect.fromCenter(center: Offset(x, y), width: w, height: h),
    brush
      ..color = color
      ..style = PaintingStyle.fill,
  );
  void dot(double x, double y, double r, Color color) => c.drawCircle(
    Offset(x, y),
    r,
    brush
      ..color = color
      ..style = PaintingStyle.fill,
  );
  void fill(Path path, Color color) => c.drawPath(
    path,
    brush
      ..color = color
      ..style = PaintingStyle.fill,
  );
  void wash(Path path, Rect bounds, List<Color> colors) {
    c.drawPath(
      path,
      brush
        ..color = Colors.white
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(bounds),
    );
    brush.shader = null;
  }

  void stroke(Path path, Color color, double width) => c.drawPath(
    path,
    brush
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  void line(
    double x,
    double y,
    double x2,
    double y2,
    Color color,
    double width,
  ) => stroke(
    Path()
      ..moveTo(x, y)
      ..lineTo(x2, y2),
    color,
    width,
  );
  void leaf(double x, double y, double length, double angle, Color color) {
    c.save();
    c.translate(x, y);
    c.rotate(angle + wind(x * 1.3 + y + length) * .14);
    fill(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(
          -length * .65,
          -length * .6,
          -length * .4,
          -length * 1.1,
          0,
          -length,
        )
        ..cubicTo(
          length * .52,
          -length * .7,
          length * .42,
          -length * .25,
          0,
          0,
        ),
      color,
    );
    line(0, -2, 0, -length * .8, const Color(0x809FB68A), .7);
    c.restore();
  }

  void tree(double x, double y, double scale, int kind) {
    c.save();
    c.translate(x, y);
    c.scale(scale);
    // Each tree has a stable silhouette and lean, rather than a repeated stamp.
    c.scale(1 + math.sin(x * .07) * .12, 1 + math.cos(x * .04) * .08);
    c.rotate(math.sin(x * .03) * .035);
    final sway = wind(x + y * .3, strength: .055 + (x.abs() % 3) * .006);
    oval(1, 3, 68, 12, const Color(0x2647694A));
    fill(
      Path()
        ..moveTo(-9, 0)
        ..quadraticBezierTo(-5, -49, -9, -102)
        ..lineTo(8, -110)
        ..quadraticBezierTo(3, -48, 12, 0)
        ..close(),
      bark,
    );
    stroke(
      Path()
        ..moveTo(-1, -7)
        ..quadraticBezierTo(1, -33, -2, -61)
        ..moveTo(3, -20)
        ..lineTo(6, -31),
      const Color(0xFFB49670),
      1.5,
    );
    c.save();
    c.translate(0, -50);
    c.rotate(sway * .7);
    c.translate(0, 50);
    stroke(
      Path()
        ..moveTo(0, -50)
        ..quadraticBezierTo(-22, -68, -30, -89)
        ..moveTo(2, -67)
        ..quadraticBezierTo(24, -83, 32, -106),
      bark,
      5,
    );
    c.restore();
    c.save();
    c.translate(0, -43);
    c.rotate(sway);
    final colors = homePalette
        ? kind == 1
              ? const [Color(0xFFD883A5), Color(0xFFF0B0C7), Color(0xFFFFE1D7)]
              : x < 75
              ? const [Color(0xFF3E8058), Color(0xFF79B574), Color(0xFFD4E89A)]
              : x > 240
              ? const [Color(0xFFC68149), Color(0xFFEABB64), Color(0xFFFFE2A4)]
              : const [Color(0xFF8C71AB), Color(0xFFBAA0D5), Color(0xFFE7D4EE)]
        : kind == 1
        ? [
            const Color(0xFFCF9DAB),
            const Color(0xFFE6B3B9),
            const Color(0xFFF1C9C6),
          ]
        : season == ForestSeason.autumn
        ? [
            const Color(0xFFB77454),
            const Color(0xFFD5A268),
            const Color(0xFFE4C188),
          ]
        : season == ForestSeason.winter
        ? [
            const Color(0xFF839A98),
            const Color(0xFFA7BCB7),
            const Color(0xFFCFD8C7),
          ]
        : season == ForestSeason.summer
        ? [
            const Color(0xFF497956),
            const Color(0xFF739D6A),
            const Color(0xFFACBE7D),
          ]
        : x > 300
        ? [
            const Color(0xFF688165),
            const Color(0xFF98AC80),
            const Color(0xFFCDD0A1),
          ]
        : [
            const Color(0xFF537C68),
            const Color(0xFF719580),
            const Color(0xFF9BB488),
          ];
    // Scalloped, hand-shaped canopy, offset highlight and stippled foliage.
    final canopy = Path()
      ..moveTo(-54, -14)
      ..cubicTo(-76, -42, -61, -65, -44, -71)
      ..cubicTo(-51, -96, -28, -111, -13, -107)
      ..cubicTo(-2, -137, 32, -129, 36, -104)
      ..cubicTo(65, -109, 76, -82, 62, -65)
      ..cubicTo(88, -41, 68, -12, 49, -9)
      ..cubicTo(28, 9, 7, 2, -4, 0)
      ..cubicTo(-26, 14, -51, 7, -54, -14)
      ..close();
    wash(canopy, const Rect.fromLTWH(-75, -135, 160, 150), [
      colors[1],
      colors[0],
    ]);
    if (season == ForestSeason.winter) {
      stroke(
        Path()
          ..moveTo(-43, -91)
          ..quadraticBezierTo(-23, -111, -12, -107)
          ..quadraticBezierTo(8, -133, 31, -113),
        const Color(0xCFFAF9ED),
        6,
      );
    }
    fill(
      Path()
        ..moveTo(-44, -67)
        ..cubicTo(-42, -98, -10, -91, -6, -112)
        ..cubicTo(13, -130, 34, -108, 31, -89)
        ..cubicTo(52, -91, 56, -60, 38, -52)
        ..cubicTo(16, -32, -20, -41, -44, -67),
      colors[1].withValues(alpha: .6),
    );
    for (var i = 0; i < 16; i++) {
      final a = i * 2.399;
      final r = 14 + (i % 4) * 10.0;
      leaf(
        math.cos(a) * r,
        -58 + math.sin(a) * r,
        6 + (i % 3) * 2,
        a * .4,
        colors[2],
      );
    }
    if (kind == 1) {
      for (var i = 0; i < 9; i++) {
        final a = i * 2.2;
        flower(
          math.cos(a) * 38,
          -55 + math.sin(a) * 34,
          .33,
          const Color(0xFFFFF2DA),
          false,
        );
      }
    }
    c.restore();
    c.restore();
  }

  void flower(double x, double y, double s, Color color, bool stem) {
    c.save();
    c.translate(x, y);
    c.scale(s);
    if (stem) c.translate(0, 25);
    c.rotate(wind(x + y * .6 + color.toARGB32() % 13) * (stem ? .22 : .07));
    if (stem) c.translate(0, -25);
    if (stem) {
      stroke(
        Path()
          ..moveTo(0, 25)
          ..quadraticBezierTo(5, 12, 0, 0),
        const Color(0xFF638953),
        2.3,
      );
      leaf(2, 18, 12, -.85, const Color(0xFF8CA568));
    }
    c.save();
    final open = .6 + .4 * Curves.easeOut.transform(bloom.value);
    c.scale(open);
    for (var i = 0; i < 5; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / 5);
      oval(0, -6, 9, 13, color);
      c.restore();
    }
    dot(0, 0, 4.5, const Color(0xFFE5B55B));
    dot(-1, -1, 1.3, const Color(0xFFFFF0AC));
    c.restore();
    c.restore();
  }

  void mushroom(double x, double y, double s, Color cap) {
    c.save();
    c.translate(x, y);
    c.scale(s);
    fill(
      Path()
        ..moveTo(-3, 0)
        ..quadraticBezierTo(-1, -9, -3, -17)
        ..lineTo(4, -17)
        ..quadraticBezierTo(2, -9, 5, 0)
        ..close(),
      const Color(0xFFF4E1B8),
    );
    fill(
      Path()
        ..moveTo(-15, -14)
        ..cubicTo(-16, -25, -6, -34, 0, -34)
        ..cubicTo(11, -35, 18, -23, 16, -14)
        ..quadraticBezierTo(0, -9, -15, -14),
      cap,
    );
    oval(0, -14, 30, 5, const Color(0xFFECCBA8));
    oval(-6, -24, 5, 4, const Color(0xFFFFF3DD));
    oval(5, -28, 4, 4, const Color(0xFFFFF3DD));
    oval(10, -20, 4, 3, const Color(0xFFFFF3DD));
    c.restore();
  }

  void rabbit(double x, double y) =>
      RabbitMascot.paintInForest(c, Offset(x, y), seconds: time * 2.2);

  void forestFriend(String id, double x, double y) {
    c.save();
    c.translate(x, y);
    final coat = switch (id) {
      'squirrel' => const Color(0xFFC77A48),
      'hedgehog' => const Color(0xFFB89569),
      'tanuki' => const Color(0xFF9A795D),
      _ => const Color(0xFFB8845A),
    };
    oval(0, 2, 39, 8, const Color(0x33415E3B));
    if (id == 'squirrel') {
      fill(
        Path()
          ..moveTo(9, -17)
          ..cubicTo(42, -21, 35, -57, 17, -50)
          ..cubicTo(4, -45, 17, -33, 24, -37)
          ..cubicTo(31, -40, 28, -24, 9, -17)
          ..close(),
        const Color(0xFFD9925B),
      );
    }
    if (id == 'hedgehog') {
      final spikes = Path()..moveTo(-18, -15);
      for (var i = 0; i < 7; i++) {
        spikes.lineTo(-19 + i * 6, -31 - (i.isEven ? 4 : 0));
        spikes.lineTo(-16 + i * 6, -16);
      }
      spikes.close();
      fill(spikes, const Color(0xFF806B57));
    }
    oval(0, -15, 36, 34, coat);
    oval(0, -9, 24, 18, const Color(0xFFFFE9D0));
    if (id == 'fawn') {
      oval(-9, -21, 10, 14, coat);
      oval(9, -21, 10, 14, coat);
      for (final dx in [-8.0, 1.0, 9.0]) {
        oval(dx, -18, 3, 3, const Color(0xFFFFE6B5));
      }
      fill(
        Path()
          ..moveTo(-9, -27)
          ..lineTo(-14, -36)
          ..lineTo(-5, -31)
          ..lineTo(-2, -39)
          ..lineTo(1, -28)
          ..close(),
        const Color(0xFF9D7954),
      );
      fill(
        Path()
          ..moveTo(2, -28)
          ..lineTo(7, -38)
          ..lineTo(8, -30)
          ..lineTo(16, -35)
          ..lineTo(11, -25)
          ..close(),
        const Color(0xFF9D7954),
      );
    } else {
      fill(
        Path()
          ..moveTo(-14, -25)
          ..lineTo(-17, -39)
          ..lineTo(-5, -30)
          ..lineTo(0, -34)
          ..lineTo(14, -39)
          ..lineTo(12, -24)
          ..close(),
        coat,
      );
      oval(-10, -20, 7, 10, const Color(0xFFFFD9C9));
      oval(10, -20, 7, 10, const Color(0xFFFFD9C9));
    }
    if (id == 'tanuki') {
      oval(-8, -17, 13, 8, const Color(0xFF58483F));
      oval(8, -17, 13, 8, const Color(0xFF58483F));
    }
    dot(-7, -18, 1.8, ink);
    dot(7, -18, 1.8, ink);
    oval(0, -9, 4, 3, const Color(0xFF75483B));
    oval(-8, -7, 7, 4, const Color(0x55E98F8C));
    oval(8, -7, 7, 4, const Color(0x55E98F8C));
    oval(-7, 0, 13, 6, coat);
    oval(7, 0, 13, 6, coat);
    c.restore();
  }

  void fox(double x, double y) {
    c.save();
    c.translate(x, y);
    oval(0, 2, 48, 9, const Color(0x25496E4A));
    fill(
      Path()
        ..moveTo(8, 0)
        ..cubicTo(42, 4, 42, -30, 27, -33)
        ..cubicTo(17, -34, 24, -15, 8, -12)
        ..close(),
      const Color(0xFFC7835C),
    );
    fill(
      Path()
        ..moveTo(28, -28)
        ..quadraticBezierTo(38, -24, 28, -11)
        ..quadraticBezierTo(38, -14, 36, -24)
        ..close(),
      const Color(0xFFFFEACF),
    );
    oval(0, -12, 30, 32, const Color(0xFFD99469));
    fill(
      Path()
        ..moveTo(-18, -29)
        ..lineTo(-17, -55)
        ..lineTo(-3, -45)
        ..lineTo(9, -55)
        ..lineTo(14, -31)
        ..quadraticBezierTo(1, -11, -18, -29),
      const Color(0xFFD99469),
    );
    fill(
      Path()
        ..moveTo(-16, -32)
        ..quadraticBezierTo(-5, -31, -2, -24)
        ..quadraticBezierTo(4, -31, 12, -32)
        ..quadraticBezierTo(-2, -13, -16, -32),
      const Color(0xFFFFEACF),
    );
    dot(-9, -35, 1.5, ink);
    dot(5, -35, 1.5, ink);
    dot(-2, -25, 2, ink);
    oval(-6, 1, 12, 5, const Color(0xFF9E664C));
    c.restore();
  }

  void bird(double x, double y, double s) {
    c.save();
    c.translate(x, y);
    c.scale(s);
    fill(
      Path()
        ..moveTo(-13, 1)
        ..lineTo(-24, -9)
        ..lineTo(-19, 8)
        ..quadraticBezierTo(-1, 21, 13, 4)
        ..cubicTo(22, -12, 5, -20, -1, -9)
        ..quadraticBezierTo(-7, -11, -13, 1),
      const Color(0xFF6D9BA9),
    );
    oval(0, 6, 17, 14, const Color(0xFFF6E6BA));
    fill(
      Path()
        ..moveTo(-12, 0)
        ..quadraticBezierTo(-1, -6, 5, 4)
        ..quadraticBezierTo(-6, 13, -12, 0),
      const Color(0xFF99BFBD),
    );
    dot(9, -6, 1.4, ink);
    fill(
      Path()
        ..moveTo(15, -6)
        ..lineTo(22, -3)
        ..lineTo(15, 0)
        ..close(),
      const Color(0xFFD4A45D),
    );
    c.restore();
  }

  void butterfly(double baseX, double baseY, double phase, Color color) {
    // A slow closed flight path; wings rest briefly between flights.
    final flight = (1 - math.cos(time + phase)) / 2;
    final a = time + phase;
    c.save();
    c.translate(
      baseX + math.sin(a) * 16 * flight,
      baseY + math.sin(a * 2) * 6 * flight,
    );
    c.rotate(math.sin(a) * .2);
    final flutter =
        .8 - .3 * flight + .3 * flight * math.sin(time * 5 + phase).abs();
    c.save();
    c.scale(flutter, 1);
    fill(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(-25, -29, -24, 12, -6, 3)
        ..cubicTo(-23, 8, -10, 25, 0, 4)
        ..cubicTo(10, 25, 23, 8, 6, 3)
        ..cubicTo(24, 12, 25, -29, 0, 0),
      color,
    );
    dot(-10, -7, 3, const Color(0xFFFFF1CF));
    dot(10, -7, 3, const Color(0xFFFFF1CF));
    c.restore();
    line(0, -5, 0, 10, ink, 1.6);
    stroke(
      Path()
        ..moveTo(0, -4)
        ..quadraticBezierTo(-3, -12, -6, -10)
        ..moveTo(0, -4)
        ..quadraticBezierTo(3, -12, 6, -10),
      ink,
      .8,
    );
    c.restore();
  }

  void shopPlants() {
    final opening = Curves.easeOut.transform(bloom.value);
    if (items.contains('tulip')) {
      oval(127, 304, 51, 7, const Color(0x28415E3B));
      for (var i = 0; i < 3; i++) {
        c.save();
        c.translate(111.0 + i * 16, 303.0 - (i % 2) * 8);
        c.scale(.7 + .3 * opening);
        final sway = wind(111.0 + i * 23) * 7;
        stroke(
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(sway * .25, -18, sway, -32),
          const Color(0xFF51794D),
          2.5,
        );
        leaf(0, -8, 15, -.9, const Color(0xFF6B955C));
        leaf(0, -13, 13, .8, const Color(0xFF84A265));
        c.translate(sway, -32);
        c.rotate(sway * .025);
        fill(
          Path()
            ..moveTo(-11, -14)
            ..lineTo(-3, -8)
            ..lineTo(1, -17)
            ..lineTo(6, -8)
            ..lineTo(12, -13)
            ..cubicTo(15, 13, -14, 15, -11, -14)
            ..close(),
          i == 1 ? const Color(0xFFF2BD70) : const Color(0xFFCF7188),
        );
        line(0, 2, 1, -8, const Color(0x80FFF1CF), 1.3);
        c.restore();
      }
    }
    if (items.contains('sunflower')) {
      oval(259, 304, 28, 6, const Color(0x28415E3B));
      c.save();
      c.translate(259, 303);
      c.scale(.8 + .2 * opening);
      final sway = wind(259, strength: 8);
      stroke(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(sway * .3, -28, sway, -49),
        const Color(0xFF587746),
        3,
      );
      leaf(0, -13, 19, -1, const Color(0xFF759655));
      leaf(0, -23, 16, .9, const Color(0xFF8EAA66));
      c.translate(sway, -52);
      c.rotate(wind(275) * .12);
      for (var i = 0; i < 12; i++) {
        c.save();
        c.rotate(i * math.pi / 6);
        oval(
          0,
          -14,
          9,
          20,
          i.isEven ? const Color(0xFFF4C35D) : const Color(0xFFECAF48),
        );
        c.restore();
      }
      dot(0, 0, 11, const Color(0xFF805537));
      for (var i = 0; i < 7; i++) {
        dot(
          math.cos(i * 2.4) * 6,
          math.sin(i * 2.4) * 6,
          1,
          const Color(0xFFC39760),
        );
      }
      c.restore();
    }
    if (items.contains('mushroom')) {
      oval(346, 311, 33, 6, const Color(0x28415E3B));
      mushroom(337, 309, .65 + .25 * opening, const Color(0xFFAB7790));
      mushroom(354, 314, .4 + .2 * opening, const Color(0xFFCC9763));
    }
    if (items.contains('butterfly')) {
      c.save();
      c.translate(94, 114);
      c.scale(.7 + .3 * opening);
      butterfly(0, 0, 1, const Color(0xFF659DAF));
      c.restore();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    c = canvas;
    time = breeze.value * math.pi * 2;
    c.save();
    c.scale(size.width / 420, size.height / 320);
    final sky = const Rect.fromLTWH(0, 0, 420, 320);
    if (!foregroundOnly) {
      c.drawRect(
        sky,
        brush
          ..color = Colors.white
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: homePalette
                ? switch (daylight) {
                    ForestTime.morning => const [
                      Color(0xFFF8DED3),
                      Color(0xFFFFF1D1),
                    ],
                    ForestTime.day => const [
                      Color(0xFFCAE9EF),
                      Color(0xFFFFF0C9),
                    ],
                    ForestTime.evening => const [
                      Color(0xFFCBB4D7),
                      Color(0xFFF8D49D),
                    ],
                    ForestTime.night => const [
                      Color(0xFF405B7A),
                      Color(0xFF9FB6BA),
                    ],
                  }
                : switch (daylight) {
                    ForestTime.morning => const [
                      Color(0xFFF6DFCC),
                      Color(0xFFF5F1D9),
                    ],
                    ForestTime.evening => const [
                      Color(0xFFD5A1A0),
                      Color(0xFFF5D39B),
                    ],
                    ForestTime.night => const [
                      Color(0xFF293E60),
                      Color(0xFF7B92A4),
                    ],
                    ForestTime.day => switch (season) {
                      ForestSeason.spring => const [
                        Color(0xFFE4EEF0),
                        Color(0xFFF9E9D8),
                      ],
                      ForestSeason.summer => const [
                        Color(0xFFD6ECED),
                        Color(0xFFF5EDCE),
                      ],
                      ForestSeason.autumn => const [
                        Color(0xFFE8E7DA),
                        Color(0xFFF5E0B9),
                      ],
                      ForestSeason.winter => const [
                        Color(0xFFDCE5EB),
                        Color(0xFFF2F3ED),
                      ],
                    },
                  },
          ).createShader(sky),
      );
      brush.shader = null;
      if (daylight == ForestTime.night) {
        dot(326, 49, 23, const Color(0xFFF7E9BE));
        dot(317, 43, 4, const Color(0xFFE6D7AD));
        dot(334, 57, 3, const Color(0xFFE6D7AD));
        for (var i = 0; i < 17; i++) {
          dot(
            19.0 + (i * 67) % 386,
            12.0 + (i * 23) % 92,
            i.isEven ? 1.3 : .8,
            const Color(0xFFECE7CF),
          );
        }
      } else {
        dot(326, 49, 28, const Color(0xFFF4CE83));
        dot(319, 42, 19, const Color(0xFFFFDF9B));
      }
      for (final (x, y) in [(83.0, 38.0), (260.0, 24.0)]) {
        c.save();
        c.translate(math.sin(time) * 7, math.cos(time) * 1.2);
        fill(
          Path()
            ..moveTo(x - 30, y + 8)
            ..cubicTo(x - 38, y - 5, x - 20, y - 13, x - 10, y - 6)
            ..cubicTo(x - 2, y - 23, x + 19, y - 16, x + 20, y - 4)
            ..cubicTo(x + 43, y - 5, x + 41, y + 13, x + 25, y + 12)
            ..close(),
          daylight == ForestTime.night
              ? const Color(0x407C8EA3)
              : const Color(0xCFFFF9EA),
        );
        c.restore();
      }
      if (homePalette) {
        final light = daylight == ForestTime.night
            ? .045
            : .09 + math.sin(time) * .02;
        fill(
          Path()
            ..moveTo(322, 48)
            ..lineTo(128, 264)
            ..lineTo(190, 273)
            ..close(),
          const Color(0xFFFFE6A1).withValues(alpha: light),
        );
        fill(
          Path()
            ..moveTo(332, 48)
            ..lineTo(238, 272)
            ..lineTo(275, 267)
            ..close(),
          const Color(0xFFFFF2C9).withValues(alpha: light),
        );
      }
      // Cool, softened silhouettes recede behind the warm meadow and foreground.
      for (var i = 0; i < 6; i++) {
        final x = 76.0 + i * 51;
        final top = 108.0 + (i % 3) * 12;
        fill(
          Path()
            ..moveTo(x - 25, 184)
            ..cubicTo(x - 38, top + 37, x - 18, top + 27, x - 16, top + 17)
            ..cubicTo(x - 12, top - 14, x + 19, top - 7, x + 20, top + 18)
            ..cubicTo(x + 42, top + 31, x + 27, top + 63, x + 31, 184)
            ..close(),
          i.isEven ? const Color(0xFFB4C9BD) : const Color(0xFFC4D2BD),
        );
        line(x, 180, x - 3, top + 31, const Color(0xFFA4B9AB), 2);
      }
      fill(
        Path()
          ..moveTo(0, 180)
          ..quadraticBezierTo(90, 112, 220, 170)
          ..quadraticBezierTo(334, 120, 420, 160)
          ..lineTo(420, 320)
          ..lineTo(0, 320)
          ..close(),
        homePalette && season != ForestSeason.winter
            ? const Color(0xFFC4DBAA)
            : season == ForestSeason.winter
            ? const Color(0xFFCCD9D1)
            : season == ForestSeason.autumn
            ? const Color(0xFFCBC79F)
            : const Color(0xFFB9CEAD),
      );
      tree(37, 218, .94, 0);
      tree(377, 212, .96, growth >= 6 ? 1 : 0);
      if (growth >= 5) tree(294, 214, .55, 0);
      fill(
        Path()
          ..moveTo(0, 236)
          ..quadraticBezierTo(70, 199, 185, 235)
          ..quadraticBezierTo(304, 190, 420, 227)
          ..lineTo(420, 320)
          ..lineTo(0, 320)
          ..close(),
        homePalette && season != ForestSeason.winter
            ? const Color(0xFFACCA89)
            : season == ForestSeason.winter
            ? const Color(0xFFE8EDE3)
            : season == ForestSeason.autumn
            ? const Color(0xFFB7B182)
            : const Color(0xFFA4BC89),
      );
      fill(
        Path()
          ..moveTo(153, 320)
          ..cubicTo(197, 278, 300, 264, 243, 223)
          ..cubicTo(277, 259, 221, 280, 234, 320)
          ..close(),
        const Color(0xFFF3DCAF),
      );
      stroke(
        Path()
          ..moveTo(163, 319)
          ..cubicTo(205, 279, 296, 264, 248, 232),
        const Color(0x50FFF9DF),
        3,
      );
      for (var i = 0; i < 28; i++) {
        final x = 10.0 + (i * 83) % 395;
        final y = 235.0 + (i * 17) % 78;
        stroke(
          Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(x + 3, y - 2, x + 7, y - 1),
          const Color(0x25839B65),
          1,
        );
      }
    }
    // The central clearing grows from seedling to flowering tree.
    if (foregroundOnly) {
      wash(
        Path()
          ..moveTo(0, 320)
          ..lineTo(0, 292)
          ..cubicTo(65, 258, 118, 242, 180, 250)
          ..cubicTo(270, 231, 351, 260, 420, 286)
          ..lineTo(420, 320)
          ..close(),
        const Rect.fromLTWH(0, 245, 420, 75),
        const [Color(0xFFBCD39A), Color(0x006E9366)],
      );
    }
    if (growth < 2) {
      oval(163, 247, 39, 9, const Color(0xFF839C6D));
      line(163, 246, 163, growth == 0 ? 228 : 208, const Color(0xFF638552), 3);
      leaf(
        163,
        growth == 0 ? 232 : 221,
        growth == 0 ? 13 : 20,
        -1.1,
        const Color(0xFF6D925B),
      );
      leaf(
        163,
        growth == 0 ? 229 : 212,
        growth == 0 ? 15 : 22,
        .95,
        const Color(0xFF8EA868),
      );
    } else {
      tree(158, 244, .43 + math.min(growth - 2, 5) * .105, growth >= 6 ? 1 : 0);
    }
    if (items.contains('cherry')) {
      final opening = Curves.easeOut.transform(bloom.value);
      tree(262, 231, .62 + .08 * opening, 1);
      for (var i = 0; i < 5; i++) {
        flower(
          225.0 + i * 17,
          240.0 + (i % 2) * 6,
          .4,
          const Color(0xFFE5A1B4),
          false,
        );
      }
    }
    // Ground cover is composed as a border, leaving the path and faces clear.
    for (var i = 0; i < (foregroundOnly ? 0 : 26); i++) {
      final x = ((i * 67 + 13) % 420).toDouble();
      final y = 263 + (i % 5) * 11.0;
      leaf(
        x,
        y,
        10 + (i % 4) * 3.0,
        (i % 2 == 0 ? -.6 : .6) + wind(x + i * 11) * .12,
        i % 3 == 0 ? const Color(0xFF6F956C) : const Color(0xFF8FA975),
      );
    }
    for (
      var i = 0;
      i < (foregroundOnly ? 3 : 5) + math.min(growth, 8) * 2;
      i++
    ) {
      final x = 22.0 + (i * 79) % 382;
      final y = 257.0 + (i * 13) % 51;
      final palette = homePalette
          ? const [
              Color(0xFFE382AC),
              Color(0xFFFFD263),
              Color(0xFFA489CF),
              Color(0xFFF0A366),
            ]
          : [
              const Color(0xFFE5A09B),
              const Color(0xFFFBE9B5),
              const Color(0xFFADABD0),
              const Color(0xFFE8BB77),
            ];
      flower(
        x,
        y,
        (homePalette ? .62 : .48) + (i % 3) * .12,
        palette[i % 4],
        true,
      );
    }
    mushroom(64, 281, .8, const Color(0xFFC87967));
    if (growth >= 2) {
      mushroom(88, 290, .58, const Color(0xFFD9A264));
      butterfly(218, 154, 0, const Color(0xFFE5B16F));
    }
    if (friends == null && growth >= 3 && showRabbit) rabbit(310, 274);
    if (friends != null) {
      for (final entry in const {
        'rabbit': Offset(310, 274),
        'squirrel': Offset(122, 238),
        'hedgehog': Offset(354, 250),
        'tanuki': Offset(68, 204),
        'fawn': Offset(333, 193),
      }.entries) {
        if (!friends!.contains(entry.key) ||
            (entry.key == 'rabbit' && !showRabbit)) {
          continue;
        }
        if (entry.key == 'rabbit') {
          rabbit(entry.value.dx, entry.value.dy);
        } else {
          forestFriend(entry.key, entry.value.dx, entry.value.dy);
        }
      }
    }
    if (homePalette && growth < 2) {
      butterfly(218, 154, 0, const Color(0xFFE6B951));
    }
    if (homePalette && growth < 4) bird(111, 163, .75);
    if (growth >= 4) {
      mushroom(366, 278, .9, const Color(0xFFC87967));
      bird(111, 163, .75);
    }
    if (growth >= 6) butterfly(290, 111, 2, const Color(0xFFAFABD0));
    if (growth >= 8) {
      fox(70, 263);
      bird(278, 180, .8);
      butterfly(116, 183, 4, const Color(0xFFD7A4B0));
    }
    shopPlants();
    if (season == ForestSeason.spring) {
      for (var i = 0; i < 6; i++) {
        flower(
          24.0 + i * 68,
          274.0 + (i % 3) * 13,
          .55,
          const Color(0xFFE7B4C0),
          true,
        );
      }
    } else if (season == ForestSeason.autumn) {
      for (var i = 0; i < 13; i++) {
        leaf(
          15.0 + (i * 43) % 390,
          278.0 + (i * 17) % 39,
          8,
          i * .8,
          i.isEven ? const Color(0xFFC88657) : const Color(0xFFD8B46E),
        );
      }
    } else if (season == ForestSeason.winter) {
      for (var i = 0; i < 22; i++) {
        dot(
          9.0 + (i * 53) % 399,
          35.0 + (i * 37) % 260 + math.sin(time + i) * 3,
          1.5,
          const Color(0xCFFFFDF4),
        );
      }
    }
    for (final (x, direction) in [(8.0, 1.0), (409.0, -1.0)]) {
      final bend = wind(x, strength: 8);
      stroke(
        Path()
          ..moveTo(x, 323)
          ..quadraticBezierTo(
            x + direction * 10 + bend * .3,
            300,
            x + direction * 4 + bend,
            276,
          ),
        const Color(0xFF667E52),
        2,
      );
      for (var i = 0; i < 4; i++) {
        leaf(
          x + direction * 6 + bend * (i + 1) / 5,
          312 - i * 9.0,
          15 - i * 1.5,
          direction * (i.isEven ? -.9 : .8),
          i.isEven ? const Color(0xFFA9AF79) : const Color(0xFF74916B),
        );
      }
    }
    // Three sparse leaves drift only during part of the cycle. No bursts.
    for (var i = 0; i < 3; i++) {
      final progress = (time / (math.pi * 2) + i * .29) % 1;
      if (progress < .58 && breeze.isAnimating) {
        final flight = progress / .58;
        final alpha = math.sin(flight * math.pi) * .85;
        leaf(
          44 + i * 137 + flight * 27 + math.sin(flight * 7 + i) * 8,
          97 + i * 13 + flight * 144,
          6 + i.toDouble(),
          flight * 4 + i,
          (season == ForestSeason.autumn
                  ? const Color(0xFFC7935C)
                  : const Color(0xFF9CAB75))
              .withValues(alpha: alpha),
        );
      }
    }
    // Tiny cream stipples suggest printed-paper texture without a costly filter.
    for (var i = 0; i < 180; i++) {
      dot(
        (i * 83 % 419).toDouble(),
        (i * 47 % 319).toDouble(),
        i.isEven ? .4 : .7,
        const Color(0x2CFFF6DD),
      );
    }
    if (!foregroundOnly && daylight != ForestTime.day) {
      c.drawRect(
        sky,
        brush
          ..shader = null
          ..style = PaintingStyle.fill
          ..color = homePalette && daylight == ForestTime.night
              ? const Color(0x103A507C)
              : switch (daylight) {
                  ForestTime.morning => const Color(0x0DF9D3A0),
                  ForestTime.evening => const Color(0x15D98467),
                  ForestTime.night => const Color(0x283A507C),
                  ForestTime.day => Colors.transparent,
                },
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_Woodland old) =>
      growth != old.growth ||
      showRabbit != old.showRabbit ||
      season != old.season ||
      daylight != old.daylight ||
      homePalette != old.homePalette ||
      foregroundOnly != old.foregroundOnly ||
      !setEquals(friends, old.friends) ||
      !setEquals(items, old.items) ||
      old.breeze != breeze ||
      old.bloom != bloom;
}

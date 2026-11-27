import 'storybook_surface.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'monetization_ads.dart';
import 'first_steps.dart';
import 'press_feedback.dart';
import 'kana_keyboard.dart';
import 'coin_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'forest_scene.dart';
import 'forest_shop_house.dart';
import 'rabbit_mascot.dart';
import 'rabbit_sendoff.dart';
import 'puzzle_backdrop.dart';
import 'forest_audio.dart';
import 'success_petals.dart';
import 'game.dart';
import 'letter_board.dart';
import 'title_screen.dart';
import 'petal_transition.dart';
import 'legal.dart';
import 'invitation.dart';
import 'invitation_panel.dart';
import 'fantasy_backdrop.dart';
import 'stage_journey.dart';
import 'stage_map.dart';

const green = forestGreen;
const cream = Color(0xFFFAF6EA);

class _HintWoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(15)),
    );
    final grain = Paint()
      ..color = const Color(0x22784A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (.22 + i * .31);
      final path = Path()
        ..moveTo(-8, y)
        ..cubicTo(
          size.width * .25,
          y - 8,
          size.width * .55,
          y + 8,
          size.width + 8,
          y - 2,
        );
      canvas.drawPath(path, grain);
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .83, size.height * .76),
        width: 20,
        height: 9,
      ),
      grain,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DailyChestArt extends StatelessWidget {
  final bool open;
  const DailyChestArt({super.key, required this.open});

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: open ? .78 : 1,
    child: Image.asset(
      'assets/art/daily-reward-chest.png',
      fit: BoxFit.contain,
      width: 112,
      height: 92,
      filterQuality: FilterQuality.medium,
    ),
  );
}

class _ChestSparkle extends StatefulWidget {
  const _ChestSparkle();

  @override
  State<_ChestSparkle> createState() => _ChestSparkleState();
}

class _ChestSparkleState extends State<_ChestSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: .4, end: 1).animate(_controller),
    child: ScaleTransition(
      scale: Tween<double>(begin: .8, end: 1.08).animate(_controller),
      child: const Icon(Icons.auto_awesome, size: 15, color: Color(0xFFFFD36A)),
    ),
  );
}

class _CoinBurst extends StatelessWidget {
  final bool reduceMotion;
  const _CoinBurst({required this.reduceMotion});

  static const _flight = <Offset>[
    Offset(-48, -28),
    Offset(-25, -43),
    Offset(0, -48),
    Offset(27, -40),
    Offset(49, -23),
    Offset(39, 23),
  ];

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < _flight.length; i++)
          TweenAnimationBuilder<double>(
            key: ValueKey('daily-coin-particle-$i'),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: reduceMotion ? 0 : 620 + i * 24),
            curve: Curves.easeOutCubic,
            builder: (context, progress, child) => Positioned(
              left: 80 + _flight[i].dx * progress - 11,
              top: 56 + _flight[i].dy * progress - 11,
              child: Opacity(
                opacity: (1 - progress).clamp(0, 1),
                child: Transform.scale(
                  scale: .75 + .25 * (1 - progress),
                  child: child,
                ),
              ),
            ),
            child: const CoinGlyph(),
          ),
      ],
    ),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MonetizationAds.initialize());
  runApp(const ForestApp());
}

class ForestApp extends StatefulWidget {
  const ForestApp({super.key});
  @override
  State<ForestApp> createState() => _ForestAppState();
}

class _ForestAppState extends State<ForestApp> with WidgetsBindingObserver {
  Timer? dayTimer;
  final forestScroll = ScrollController();
  final forestViewTransform = TransformationController();
  final shopPages = PageController(viewportFraction: .88);
  int shopIndex = 0;
  int shopThanks = 0;
  int loginGift = 0;
  bool openingDailyChest = false, homeTransitioning = false;
  bool adRewardInProgress = false;
  bool stageAdRewardInProgress = false;
  bool forestFullscreen = false;
  bool forestViewInitialized = false;
  bool confirmingPurchase = false;
  String? movingForestItem;
  final Map<String, List<double>> draftForestPositions = {};
  final Map<String, ForestItemAppearance> draftForestAppearances = {};
  int? departingLength;
  final messenger = GlobalKey<ScaffoldMessengerState>();
  Progress progress = Progress();
  StageJourney journey = StageJourney();
  SharedPreferences? prefs;
  bool ready = false;
  bool titleActive = true, showingWelcome = false;
  bool petaling = false; // petal wipe between title and home is playing
  String? storageError;
  String page = 'ホーム';
  final List<({String page, bool daily, String draft})> previousPages = [];
  final input = TextEditingController();
  bool restoringInput = false;
  Future<void> writes = Future.value();
  String feedback = '';
  bool revealing = false;
  bool dailyMode = false, celebrating = false;
  InvitationPuzzle? invitation;
  Timer? celebrationTimer;
  Word get currentWord =>
      invitation?.word ?? (dailyMode ? progress.today.word : progress.word);
  List<String> get currentGuesses =>
      invitation?.guesses ??
      (dailyMode ? progress.today.guesses : progress.guesses);
  bool get currentWon =>
      invitation?.won ??
      (dailyMode
          ? progress.today.won ||
                progress.todayClears.contains(progress.today.date)
          : progress.won);
  int get currentHints =>
      invitation?.hints ?? (dailyMode ? progress.today.hints : progress.hints);
  set currentHints(int value) {
    if (invitation != null) {
      invitation!.hints = value;
    } else if (dailyMode) {
      progress.today.hints = value;
    } else {
      progress.hints = value;
    }
  }

  int? animatedGuess;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    input.addListener(refreshInput);
    load();
  }

  bool get adCoinRewardClaimed =>
      progress.lastAdCoinRewardDate.compareTo(
        Progress.dayKey(DateTime.now()),
      ) >=
      0;

  void watchAdForCoins() {
    if (adRewardInProgress || adCoinRewardClaimed) return;
    setState(() => adRewardInProgress = true);
    final shown = MonetizationAds.showRewarded(
      onEarned: () {
        if (!mounted ||
            !progress.claimAdCoinReward(
              DateTime.now(),
              amount: MonetizationAds.dailyCoinReward,
            )) {
          return;
        }
        setState(() {});
        save();
        ForestAudio.play('reward', progress.soundEnabled);
        messenger.currentState?.showSnackBar(
          const SnackBar(content: Text('動画のお礼 ＋10コイン！')),
        );
      },
      onClosed: () {
        if (mounted) setState(() => adRewardInProgress = false);
      },
    );
    if (!shown && mounted) {
      setState(() => adRewardInProgress = false);
      messenger.currentState?.showSnackBar(
        const SnackBar(content: Text('動画を準備できませんでした。あとでもう一度お試しください。')),
      );
    }
  }

  void watchAdForStageReward(StageSession session) {
    if (stageAdRewardInProgress) return;
    final stageId = session.stage.id;
    final now = DateTime.now();
    final date = Progress.dayKey(now);
    final amount = progress.stageRewardFor(stageId, now);
    if (amount <= 0 || progress.stageAdRewardClaimed(stageId, now)) return;
    setState(() => stageAdRewardInProgress = true);
    final shown = MonetizationAds.showRewarded(
      onEarned: () {
        if (!mounted ||
            !progress.claimStageAdReward(
              stageId,
              DateTime.now(),
              rewardDate: date,
            )) {
          return;
        }
        setState(() {});
        save();
        ForestAudio.play('reward', progress.soundEnabled);
        messenger.currentState?.showSnackBar(
          SnackBar(content: Text('広告ボーナス ＋$amountコイン！')),
        );
      },
      onClosed: () {
        if (mounted) setState(() => stageAdRewardInProgress = false);
      },
    );
    if (!shown && mounted) {
      setState(() => stageAdRewardInProgress = false);
      messenger.currentState?.showSnackBar(
        const SnackBar(content: Text('動画を準備できませんでした。あとでもう一度お試しください。')),
      );
    }
  }

  void refreshInput() {
    if (invitation != null && page == 'パズル') {
      invitation!.draft = input.text;
      if (!restoringInput && invitation is StageSession) saveJourney();
    } else if (!restoringInput && page == 'パズル' && !dailyMode) {
      progress.draft = input.text;
      save();
    }
    if (mounted) setState(() {});
  }

  void restoreInput() {
    restoringInput = true;
    input.text = invitation?.draft ?? progress.draft;
    restoringInput = false;
  }

  void startNormal() {
    if (progress.mode == null) {
      if (!progress.legacyAvailable) {
        go('文字数をえらぶ');
        return;
      }
      if ([3, 4, 5].contains(progress.word.text.length)) {
        progress.selectMode(progress.word.text.length);
        save();
      }
      go('パズル');
    } else if (progress.guesses.isNotEmpty || progress.draft.isNotEmpty) {
      go('パズル');
    } else {
      go('文字数をえらぶ');
    }
  }

  void chooseLength(int length) {
    if (departingLength != null) return;
    final quiet =
        progress.reduceMotion ||
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
    if (quiet) {
      enterLength(length);
    } else {
      setState(() => departingLength = length);
    }
  }

  void completeSendoff() {
    final length = departingLength;
    if (!mounted || length == null) return;
    setState(() => departingLength = null);
    enterLength(length);
  }

  void enterLength(int length) {
    progress.selectMode(length);
    revealing = false;
    animatedGuess = null;
    restoreInput();
    save();
    go('パズル');
  }

  List<Widget> modePicker() => [
    heading('何文字であそびますか？'),
    const Text('途中の答えは、文字数ごとに残ります。'),
    for (final length in [3, 4, 5])
      panel([
        button('$length文字であそぶ', () => chooseLength(length), primary: true),
        Text(
          '${words.where((w) => w.text.length == length).length}問 ・ ${progress.modes[length]?.guesses.isNotEmpty == true || progress.modes[length]?.draft.isNotEmpty == true ? 'つづきがあります' : '何度でもあそべます'}',
        ),
      ]),
    if (progress.legacyAvailable)
      button('前の問題をつづける（${progress.legacyWord.text.length}文字）', () {
        progress.resumeLegacy();
        save();
        go('パズル');
      }),
  ];

  Future<void> load() async {
    try {
      prefs = await SharedPreferences.getInstance();
      final raw = prefs!.getString('forest_progress');
      progress = raw == null
          ? Progress(introductionSeen: false, mode: 3)
          : Progress.decode(raw);
      journey = StageJourney.decode(prefs!.getString(StageJourney.storageKey));
    } catch (_) {
      storageError = '保存を読み込めませんでした。';
    }
    if (mounted) {
      progress.refreshDay(DateTime.now());
      setState(() => ready = true);
      syncMusic();
      save();
      scheduleDay();
    }
  }

  void scheduleDay() {
    dayTimer?.cancel();
    final now = DateTime.now();
    dayTimer = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (!mounted) return;
        refreshDateAndGift();
        scheduleDay();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && departingLength != null) {
      setState(() => departingLength = null);
    }
    if (state == AppLifecycleState.resumed && ready) {
      syncMusic();
      refreshDateAndGift();
      scheduleDay();
    }
  }

  void syncMusic() {
    final track = page == 'パズル' ? 'puzzle' : 'home';
    unawaited(ForestAudio.setMusic(track, progress.musicEnabled));
  }

  void refreshDateAndGift() {
    final now = DateTime.now();
    final previousDate = progress.today.date;
    final changed = progress.refreshDay(now);
    if (dailyMode && previousDate != progress.today.date) {
      input.clear();
      revealing = false;
      animatedGuess = null;
      celebrating = false;
      celebrationTimer?.cancel();
    }
    if (changed) {
      setState(() => loginGift = 0);
      save();
    }
  }

  bool get dailyChestClaimed {
    final today = Progress.dayKey(DateTime.now());
    return progress.loginDate.compareTo(today) >= 0 ||
        progress.loginClaims.contains(today);
  }

  int get nextLoginGift =>
      loginRewards[progress.loginDay % loginRewards.length];
  bool get reduceHomeMotion =>
      progress.reduceMotion ||
      WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .disableAnimations;

  Future<void> openDailyChest(BuildContext pageContext) async {
    if (openingDailyChest || dailyChestClaimed) return;
    openingDailyChest = true;
    final now = DateTime.now();
    progress.refreshDay(now);
    final reward = progress.claimLogin(now);
    if (reward <= 0) {
      openingDailyChest = false;
      return;
    }
    setState(() => loginGift = reward);
    save();
    ForestAudio.play('reward', progress.soundEnabled);
    await showDialog<void>(
      context: pageContext,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: .72, end: 1),
          duration: Duration(milliseconds: reduceHomeMotion ? 0 : 420),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D7),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFD99A45), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66563218),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '宝箱をひらいたよ！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF654321),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 112,
                  width: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 108,
                        color: Color(0xFFFFD35C),
                      ),
                      const DailyChestArt(open: true),
                      _CoinBurst(reduceMotion: reduceHomeMotion),
                      Positioned(
                        right: 4,
                        top: 5,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(
                            milliseconds: reduceHomeMotion ? 0 : 520,
                          ),
                          builder: (context, value, child) => Transform.rotate(
                            angle: (1 - value) * -.25,
                            child: Transform.scale(scale: value, child: child),
                          ),
                          child: const Icon(
                            Icons.local_florist,
                            color: Color(0xFFE8759C),
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '＋$reward コイン！',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9B6414),
                  ),
                ),
                const SizedBox(height: 6),
                const Text('また明日、あけにきてね', style: TextStyle(fontSize: 17)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('とじる'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    openingDailyChest = false;
  }

  Future<void> enterHomePlace(String destination) async {
    if (homeTransitioning) return;
    homeTransitioning = true;
    await Future<void>.delayed(
      Duration(milliseconds: progress.reduceMotion ? 0 : 140),
    );
    if (mounted) go(destination);
    homeTransitioning = false;
  }

  Future<void> enterStageFromSignpost() async {
    if (homeTransitioning) return;
    homeTransitioning = true;
    await Future<void>.delayed(
      Duration(milliseconds: reduceHomeMotion ? 0 : 150),
    );
    if (mounted) go('ステージマップ');
    homeTransitioning = false;
  }

  void save() {
    final snapshot = progress.encode();
    writes = writes.then((_) async {
      try {
        if (prefs == null ||
            !await prefs!.setString('forest_progress', snapshot)) {
          throw StateError('save failed');
        }
        if (mounted && storageError != null) {
          setState(() => storageError = null);
        }
      } catch (_) {
        if (mounted) setState(() => storageError = '保存できませんでした。もう一度お試しください。');
      }
    });
  }

  void moveForestItem(String id, double x, double y) {
    if (!progress.ownedItems.contains(id)) return;
    if (movingForestItem == id) {
      setState(() => draftForestPositions[id] = [x, y]);
      return;
    }
    setState(() => progress.itemPositions[id] = [x, y]);
    save();
  }

  void beginForestMove(String id) {
    final position = progress.itemPositions[id];
    if (position == null) return;
    setState(() {
      movingForestItem = id;
      draftForestPositions[id] = List<double>.from(position);
    });
  }

  void finishForestMove() {
    final id = movingForestItem;
    if (id == null) return;
    final position = draftForestPositions[id];
    setState(() {
      if (position != null) {
        progress.itemPositions[id] = List<double>.from(position);
      }
      movingForestItem = null;
      draftForestPositions.remove(id);
    });
    save();
  }

  void cancelForestMove() => setState(() {
    final id = movingForestItem;
    movingForestItem = null;
    if (id != null) draftForestPositions.remove(id);
  });

  Future<void> showForestItemMenu(BuildContext context, String id) async {
    final matches = forestItems.where((entry) => entry.id == id);
    if (matches.isEmpty || !progress.ownedItems.contains(id)) return;
    final item = matches.first;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFF8E7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF513B2B),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, 'customize'),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text(
                    '大きさ・向きを変える',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, 'move'),
                  icon: const Icon(Icons.open_with_rounded),
                  label: const Text(
                    '移動する',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, 'store'),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text(
                    'しまう',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8A3E32),
                  ),
                  onPressed: () => Navigator.pop(sheetContext, 'sell'),
                  icon: const Icon(Icons.sell_outlined),
                  label: const Text(
                    '売却する',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || !context.mounted || action == null) return;
    if (action == 'customize') {
      await editForestAppearance(context, id, item);
    } else if (action == 'move') {
      beginForestMove(id);
    } else if (action == 'store') {
      storeForestItem(id);
      messenger.currentState?.showSnackBar(
        SnackBar(content: Text('${item.name}を飾り置き場にしまいました')),
      );
    } else if (action == 'sell') {
      final amount = item.price ~/ 2;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            '売却の確認',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          content: Text(
            '${item.name}を売却しますか？\n$amountコインを受け取ります。',
            style: const TextStyle(fontSize: 19, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('やめる', style: TextStyle(fontSize: 18)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('売却する', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        final received = progress.sellForestItem(id);
        if (received > 0) {
          setState(() {});
          save();
          messenger.currentState?.showSnackBar(
            SnackBar(content: Text('${item.name}を売却しました　+$receivedコイン')),
          );
        }
      }
    }
  }

  Future<void> editForestAppearance(
    BuildContext context,
    String id,
    ForestItem item,
  ) async {
    final saved =
        progress.forestAreaProgress(firstForestArea.id).itemAppearances[id] ??
        const ForestItemAppearance();
    var draft = saved;
    setState(() => draftForestAppearances[id] = draft);
    final result = await showDialog<ForestItemAppearance>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, dialogSetState) {
          void update(ForestItemAppearance next) {
            dialogSetState(() => draft = next);
            if (mounted) setState(() => draftForestAppearances[id] = next);
          }

          Widget preview() => Transform.rotate(
            angle: draft.safeRotationSteps * math.pi / 12,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(
                draft.flipped ? -draft.safeScale : draft.safeScale,
                draft.safeScale,
                1,
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Color(draft.tint ?? 0x00000000).withValues(alpha: .28),
                  BlendMode.srcATop,
                ),
                child: ForestItemArt(item: id, width: 70, height: 82),
              ),
            ),
          );

          const palette = <({String name, int? color})>[
            (name: 'そのまま', color: null),
            (name: '花もも', color: 0xFFE8759C),
            (name: 'すみれ', color: 0xFF8D75C8),
            (name: '若葉', color: 0xFF62A85A),
            (name: 'あさやけ', color: 0xFFF29A53),
          ];
          final supportsTint = id == 'tulip' || id == 'sunflower';
          return AlertDialog(
            title: Text('${item.name}を整える'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 110, child: Center(child: preview())),
                  Text(
                    '大きさ　${(draft.safeScale * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    key: const ValueKey('forest-decoration-scale'),
                    min: .7,
                    max: 1.5,
                    divisions: 16,
                    value: draft.safeScale,
                    label: '${(draft.safeScale * 100).round()}%',
                    onChanged: (value) => update(draft.copyWith(scale: value)),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            update(draft.copyWith(flipped: !draft.flipped)),
                        icon: const Icon(Icons.flip_rounded),
                        label: Text(draft.flipped ? '左右反転中' : '左右反転'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => update(
                          draft.copyWith(
                            rotationSteps: draft.safeRotationSteps + 1,
                          ),
                        ),
                        icon: const Icon(Icons.rotate_right_rounded),
                        label: Text('回転 ${draft.safeRotationSteps * 15}°'),
                      ),
                    ],
                  ),
                  if (supportsTint) ...[
                    const SizedBox(height: 12),
                    const Text(
                      '花の色',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final option in palette)
                          ChoiceChip(
                            label: Text(option.name),
                            selected: draft.tint == option.color,
                            avatar: option.color == null
                                ? null
                                : CircleAvatar(
                                    backgroundColor: Color(option.color!),
                                  ),
                            onSelected: (_) => update(
                              draft.copyWith(
                                tint: option.color,
                                clearTint: option.color == null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '色を変えると絵の質感が変わるため、この飾りは色変更に対応していません。',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF66594B),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('もどす'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, draft),
                child: const Text('この飾りにする'),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted) return;
    setState(() {
      draftForestAppearances.remove(id);
      if (result != null) {
        progress.forestAreaProgress(firstForestArea.id).itemAppearances[id] =
            result;
      }
    });
    if (result != null) save();
  }

  void storeForestItem(String id) {
    if (!progress.itemPositions.containsKey(id)) return;
    setState(() {
      progress.itemPositions.remove(id);
      if (movingForestItem == id) {
        movingForestItem = null;
        draftForestPositions.remove(id);
      }
    });
    save();
  }

  void startFromTitle() {
    if (!ready || !titleActive || showingWelcome || petaling) return;
    if (!progress.welcomeSeen) {
      setState(() => showingWelcome = true);
      return;
    }
    // First-time guests saw the welcome card; everyone else gets the petal wipe.
    final quiet =
        progress.reduceMotion ||
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
    if (quiet) {
      enterHome();
    } else {
      unawaited(ForestAudio.play('wind', progress.soundEnabled));
      setState(() => petaling = true);
    }
  }

  // Fired when the petals fully cover the screen: swap to home underneath.
  void onPetalsCovered() {
    if (titleActive) enterHome();
  }

  void onPetalsDone() {
    if (mounted) setState(() => petaling = false);
  }

  void saveJourney() {
    if (prefs == null) return;
    final snapshot = journey.encode();
    writes = writes.then((_) async {
      try {
        if (!await prefs!.setString(StageJourney.storageKey, snapshot)) {
          throw StateError('stage save');
        }
        if (mounted && storageError?.startsWith('小道') == true) {
          setState(() => storageError = null);
        }
      } catch (_) {
        if (mounted) {
          setState(() => storageError = '小道の記録を保存できませんでした。再保存を押してね。');
        }
      }
    });
  }

  bool openStage(int id) {
    if (page != 'ステージマップ') return false;
    final session = journey.start(id);
    if (session == null) return false;
    playInvitation(session);
    saveJourney();
    return true;
  }

  int? launchingStage;
  bool stageIntroRevealing = false;

  void beginStage(int id) {
    if (page != 'ステージマップ' || launchingStage != null) return;
    ForestAudio.play('stage', progress.soundEnabled);
    setState(() {
      launchingStage = id;
      stageIntroRevealing = false;
    });
  }

  void finishStageIntro(int stageId) {
    if (!mounted || launchingStage != stageId) return;
    // Stage data is local and synchronous today. If loading becomes async,
    // start it here and await it before opening the puzzle.
    if (!openStage(stageId)) {
      setState(() {
        launchingStage = null;
        stageIntroRevealing = false;
      });
      return;
    }
    // Switch the page while the intro is still opaque, then softly reveal the
    // puzzle. Fading the intro over the map exposes it for a moment.
    setState(() => stageIntroRevealing = true);
  }

  void finishWelcome() {
    if (!titleActive || !showingWelcome) return;
    progress.welcomeSeen = true;
    save();
    enterHome();
  }

  void enterHome() {
    setState(() {
      titleActive = false;
      showingWelcome = false;
    });
    syncMusic();
  }

  @override
  void dispose() {
    dayTimer?.cancel();
    celebrationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    input.removeListener(refreshInput);
    input.dispose();
    forestScroll.dispose();
    forestViewTransform.dispose();
    shopPages.dispose();
    super.dispose();
  }

  void go(String target, {bool remember = true}) {
    if (page == 'パズル' && target != 'パズル') invitation = null;
    if (target == 'ホーム') {
      previousPages.clear();
    } else if (remember && target != page) {
      previousPages.add((page: page, daily: dailyMode, draft: input.text));
    }
    ForestAudio.play('key', progress.soundEnabled);
    celebrationTimer?.cancel();
    setState(() {
      if (target != 'わたしの森') forestFullscreen = false;
      departingLength = null;
      celebrating = false;
      if (target != 'わたしの森' && movingForestItem != null) {
        draftForestPositions.remove(movingForestItem);
        movingForestItem = null;
      }
      if (target == 'パズル' && dailyMode) {
        dailyMode = false;
        revealing = false;
        animatedGuess = null;
        progress.lastReward = 0;
        progress.lastDailyBonus = false;
      }
      if (target == 'パズル') restoreInput();
      if (page == 'ホーム' && target != 'ホーム') loginGift = 0;
      page = target;
      feedback = '';
    });
    syncMusic();
    if (target == 'わたしの森') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || page != 'わたしの森') return;
        final arrivals = progress.unannouncedForestFriends;
        if (arrivals.isEmpty) return;
        progress.forestFriendAnnouncements.addAll(arrivals);
        save();
        const names = {
          'squirrel': 'りす',
          'hedgehog': 'はりねずみ',
          'tanuki': 'たぬき',
          'fawn': 'こじか',
        };
        messenger.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              '新しいおともだちが来ました！ ${arrivals.map((id) => names[id] ?? '').join('、')}が遊びに来たよ',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  void playInvitation(InvitationPuzzle puzzle) {
    invitation = puzzle;
    dailyMode = false;
    revealing = false;
    animatedGuess = null;
    go('パズル');
  }

  void goBack() {
    if (previousPages.isEmpty) {
      go('ホーム');
      return;
    }
    final previous = previousPages.removeLast();
    go(previous.page, remember: false);
    if (previous.page == 'パズル') {
      setState(() {
        dailyMode = previous.daily;
        input.text = previous.draft;
      });
    }
  }

  bool get canSubmit =>
      !currentWon &&
      !revealing &&
      !(input.value.composing.isValid && !input.value.composing.isCollapsed) &&
      normalize(input.text).characters.length == currentWord.text.length &&
      RegExp(r'^[ぁ-ゖー]+$').hasMatch(normalize(input.text));
  void submit() {
    if (invitation == null &&
        dailyMode &&
        progress.today.date != Progress.dayKey(DateTime.now())) {
      refreshDateAndGift();
      return;
    }
    if (!canSubmit) return;
    final guess = normalize(input.text);
    final accepted = invitation != null
        ? invitation!.submit(guess)
        : dailyMode
        ? progress.submitToday(guess)
        : progress.submit(guess);
    if (!accepted) return;
    if (invitation is StageSession) {
      final stage = invitation! as StageSession;
      final wasPreviouslyCleared = (journey.stars[stage.stage.id] ?? 0) > 0;
      journey.complete(stage);
      final reward = progress.claimStageClearReward(
        stage.stage.id,
        DateTime.now(),
        wasPreviouslyCleared: wasPreviouslyCleared,
      );
      stage.clearRewardAmount = reward;
      stage.clearRewardDate = Progress.dayKey(DateTime.now());
      save();
      saveJourney();
    }
    touch();
    setState(() {
      animatedGuess = currentGuesses.length - 1;
      revealing = true;
      input.clear();
      feedback = currentWon ? 'せいかい！ 森が育ちました。' : '色と記号を見て、もう一度。';
    });
    // The win cue includes a final coin-like bell: one cue, no stacked rewards.
    if (!currentWon) ForestAudio.play('wrong', progress.soundEnabled);
    if (invitation == null) save();
  }

  void openToday() {
    progress.refreshDay(DateTime.now());
    go('パズル');
    setState(() {
      dailyMode = true;
      input.clear();
      animatedGuess = null;
      revealing = false;
      progress.lastReward = 0;
      progress.lastDailyBonus = false;
    });
    save();
  }

  void showMeaning(BuildContext context) {
    ForestAudio.play('key', progress.soundEnabled);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('色と記号の見かた'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '緑 ◎：文字も場所も正しい。\n\n黄色 △：文字はあるけれど、場所が違う。\n\n灰色 ×：答えにない文字。同じ文字が多すぎるときも灰色です。',
              style: TextStyle(fontSize: 20, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('とじる'),
          ),
        ],
      ),
    );
  }

  Future<void> previewSound(String name) async {
    if (!progress.soundEnabled) return;
    await ForestAudio.stop();
    if (mounted) await ForestAudio.play(name, progress.soundEnabled);
  }

  void showSoundTest(BuildContext context) {
    if (!progress.soundEnabled) return;
    previewSound('key');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('効果音を試す'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('試したい音を押してください。端末のメディア音量で調整できます。'),
            const SizedBox(height: 12),
            for (final sound in const [
              ('key', 'タップ音'),
              ('wrong', '推測ミスの音'),
              ('win', '正解音'),
            ])
              OutlinedButton(
                onPressed: () => previewSound(sound.$1),
                child: Text(sound.$2),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ForestAudio.stop();
              Navigator.pop(context);
            },
            child: const Text('とじる'),
          ),
        ],
      ),
    );
  }

  void next() {
    if (invitation != null) {
      goBack();
      return;
    }
    if (dailyMode) {
      go('パズル');
      return;
    }
    ForestAudio.play('key', progress.soundEnabled);
    final wasLegacy = progress.mode == null;
    setState(() {
      progress.next();
      animatedGuess = null;
      revealing = false;
      input.clear();
      feedback = '';
    });
    save();
    if (wasLegacy) {
      progress.legacyAvailable = false;
      save();
      go('文字数をえらぶ');
    }
  }

  Widget heading(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.4,
    ),
  );
  Widget button(String text, VoidCallback? action, {bool primary = false}) =>
      SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: PressFeedback(
            enabled: action != null,
            child: primary
                ? page == 'ホーム'
                      ? StorybookSurface(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 60),
                            ),
                            onPressed: action,
                            child: Text(
                              text,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFF24622E),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : FilledButton(onPressed: action, child: Text(text))
                : OutlinedButton(onPressed: action, child: Text(text)),
          ),
        ),
      );
  Widget panel(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFDDE5D6)),
    ),
    child: Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );

  List<Widget> home(BuildContext context) => [
    if (!progress.introductionSeen)
      panel([
        FirstSteps(
          onDone: () {
            setState(() => progress.introductionSeen = true);
            save();
            startNormal();
          },
        ),
      ]),
    const SizedBox(height: 6),
    const Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ForestWordmark(
          fontSize: 30,
          compact: true,
          showSideDecorations: false,
        ),
      ),
    ),
    const SizedBox(height: 5),
    const Center(child: TaglineRibbon(compact: true)),
    const SizedBox(height: 8),
    SizedBox(
      height: (MediaQuery.sizeOf(context).height * .12).clamp(86, 116),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              right: 22,
              bottom: 10,
              child: RabbitMascot(
                key: ValueKey('home-mascot'),
                width: 104,
                height: 126,
              ),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 4),
    homeSignpost(),
    const SizedBox(height: 2),
    Row(
      children: [
        Expanded(
          flex: 6,
          child: homeMenu(
            progress.todayClears.contains(progress.today.date)
                ? '本日はクリア済み'
                : '今日のことば ・ 1日1問',
            const Color(0xFFFFE2D8),
            onPressed: openToday,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(flex: 4, child: dailyChest(context)),
      ],
    ),
    Row(
      children: [
        Expanded(flex: 6, child: homeMenu('わたしの森', const Color(0xFFF8DDD5))),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: homeMenu(
            'わたしの記録',
            const Color(0xFFF6E6B8),
            onPressed: () => showRecords(context),
          ),
        ),
      ],
    ),
    Row(
      children: [
        Expanded(flex: 5, child: homeMenu('あそびかた', const Color(0xFFDFEDF1))),
        const SizedBox(width: 10),
        Expanded(flex: 6, child: homeMenu('ことばの招待状', const Color(0xFFEADFF2))),
      ],
    ),
    const SizedBox(height: 8),
    wallet(),
  ];

  Widget homeSignpost() => PressFeedback(
    enabled: !homeTransitioning,
    child: Semantics(
      button: true,
      label: 'あそぶ。ステージマップへ',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('home-play-signpost'),
          onTap: homeTransitioning ? null : enterStageFromSignpost,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB96D34),
                  Color(0xFF86502D),
                  Color(0xFF704024),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFD781), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x774C2A17),
                  blurRadius: 9,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0xAAFFE7A6),
                  blurRadius: 1,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _HintWoodGrainPainter()),
                  ),
                ),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.explore_rounded,
                          color: Color(0xFFFFE78C),
                          size: 34,
                          shadows: [
                            Shadow(color: Color(0xFF472615), blurRadius: 3),
                          ],
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'あそぶ',
                          style: TextStyle(
                            fontFamily: 'ZenMaru',
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color(0xFF4E2918),
                                offset: Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  left: 8,
                  top: 4,
                  child: Icon(
                    Icons.eco_rounded,
                    color: Color(0xFFB8E26B),
                    size: 20,
                  ),
                ),
                const Positioned(
                  right: 9,
                  bottom: 4,
                  child: Icon(
                    Icons.local_florist,
                    color: Color(0xFFFFB3C8),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget dailyChest(BuildContext pageContext) {
    final claimed = dailyChestClaimed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: PressFeedback(
        enabled: !claimed && !openingDailyChest,
        child: Semantics(
          button: !claimed,
          label: claimed ? '毎日の宝箱、本日は受け取り済み' : '毎日の宝箱を開ける。$nextLoginGift コイン',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('daily-treasure-chest'),
              onTap: claimed || openingDailyChest
                  ? null
                  : () => openDailyChest(pageContext),
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 67, minWidth: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 70,
                      width: 96,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            key: ValueKey('chest-art-$claimed-$loginGift'),
                            tween: Tween(begin: .92, end: 1),
                            duration: Duration(
                              milliseconds: reduceHomeMotion ? 0 : 280,
                            ),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) =>
                                Transform.scale(scale: scale, child: child),
                            child: DailyChestArt(open: claimed),
                          ),
                          if (!claimed && !reduceHomeMotion)
                            const Positioned(
                              top: 1,
                              right: 8,
                              child: _ChestSparkle(),
                            ),
                          if (!claimed && !reduceHomeMotion)
                            const Positioned(
                              left: 8,
                              bottom: 2,
                              child: Icon(
                                Icons.auto_awesome,
                                size: 11,
                                color: Color(0xFFFFD36A),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!claimed) const SizedBox(height: 2),
                    if (!claimed)
                      Text(
                        '宝箱をあける\n＋$nextLoginGift コイン',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF4F351C),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.05,
                          shadows: const [
                            Shadow(color: Color(0xAAFFF9E9), blurRadius: 2),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget homeMenu(String name, Color color, {VoidCallback? onPressed}) {
    final isDailyWord = name.startsWith('今日のことば') || name == '本日はクリア済み';
    final icon = switch (name) {
      '今日のことば' => Icons.event_available,
      '今日のことば ・ 1日1問' => Icons.event_available,
      '本日はクリア済み' => Icons.event_available,
      'わたしの森' => Icons.park,
      'わたしの記録' => Icons.auto_stories,
      'あそびかた' => Icons.menu_book,
      'ことばの招待状' => Icons.mail,
      _ => Icons.local_florist,
    };
    final iconWidget = name.startsWith('今日のことば') || name == '本日はクリア済み'
        ? SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 25,
                  color: Color(0xFF557B35),
                ),
                Positioned(
                  right: -3,
                  bottom: -2,
                  child: Icon(
                    Icons.local_florist,
                    size: 15,
                    color: const Color(0xFFCF6D86),
                    shadows: [
                      Shadow(color: color, blurRadius: 2),
                      const Shadow(color: Colors.white, blurRadius: 1),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Icon(icon, size: 28, color: const Color(0xFF456B32));
    final action = onPressed ?? () => enterHomePlace(name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: PressFeedback(
        enabled: !homeTransitioning,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: homeTransitioning ? null : action,
            borderRadius: BorderRadius.circular(19),
            child: Container(
              constraints: const BoxConstraints(minHeight: 62),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF9E9),
                    Color.lerp(const Color(0xFFF4E2BD), color, .34)!,
                    const Color(0xFFEBD0A1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: const Color(0xFF8C633B), width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66442D1D),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Color(0xAAFFFDF3),
                    blurRadius: 1,
                    spreadRadius: .5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 41,
                    height: 41,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .76),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color.lerp(color, Colors.white, .15)!,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: iconWidget,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: isDailyWord
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '今日のことば',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'ZenMaru',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  height: 1.12,
                                  color: Color(0xFF3D3528),
                                ),
                              ),
                              Text(
                                name == '本日はクリア済み' ? name : '1日1問',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  height: 1.1,
                                  color: Color(0xFF624C39),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'ZenMaru',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              height: 1.12,
                              color: Color(0xFF3D3528),
                            ),
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

  Widget wallet() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDBE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            progress.dailyBonusGiven
                ? '今日の目標 3/3問 ・ 30コイン獲得済み'
                : '今日の目標 ${progress.dailyWords.length}/3問 ・ 達成で30コイン',
            style: const TextStyle(
              fontSize: 17,
              height: 1.3,
              color: Color(0xFF604821),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> confirmBuy(BuildContext context, ForestItem item) async {
    if (confirmingPurchase ||
        progress.ownedItems.contains(item.id) ||
        progress.coins < item.price) {
      return;
    }
    confirmingPurchase = true;
    ForestAudio.play('key', progress.soundEnabled);
    bool accepted = false;
    try {
      accepted =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('森に迎えますか？'),
              content: Text(
                '${item.name}\n${item.price} コイン\n\n購入後：${progress.coins - item.price} コイン',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('やめる'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('購入する'),
                ),
              ],
            ),
          ) ??
          false;
    } finally {
      confirmingPurchase = false;
    }
    if (accepted && mounted) await buy(item);
  }

  Future<void> buy(ForestItem item) async {
    if (!progress.purchase(item.id)) return;
    touch();
    setState(() => shopThanks++);
    ForestAudio.play('buy', progress.soundEnabled);
    save();
    // Bring the fixed placement into view; the scene blooms on the next frame.
    if (forestScroll.hasClients) {
      if (progress.reduceMotion ||
          WidgetsBinding
              .instance
              .platformDispatcher
              .accessibilityFeatures
              .disableAnimations) {
        forestScroll.jumpTo(0);
      } else {
        await forestScroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
    if (!mounted) return;
    messenger.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            RabbitMascot(
              key: ValueKey('thanks-$shopThanks'),
              mood: RabbitMood.bow,
              event: shopThanks,
              width: 64,
              height: 80,
              animateIdle: false,
              interactive: false,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${item.name}を森に迎えました。',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showHints(BuildContext context) {
    ForestAudio.play('key', progress.soundEnabled);
    if (invitation != null) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(invitation is StageSession ? 'ことばのヒント' : '届いたヒント'),
          scrollable: true,
          content: Text(
            invitation!.hint.isEmpty ? 'この問題にはヒントがありません。' : invitation!.hint,
            style: const TextStyle(fontSize: 21, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('とじる'),
            ),
          ],
        ),
      );
      return;
    }
    if (currentHints == 0) {
      setState(() => currentHints = 1);
      save();
    }
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('ことばのヒント'),
          scrollable: true,
          content: SizedBox(
            width: 360,
            child: hintCard(
              onReveal: () => refresh(() {}),
              revealKey: const ValueKey('dialog-next-hint'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('とじる'),
            ),
          ],
        ),
      ),
    );
  }

  Widget hintCard({
    VoidCallback? onReveal,
    bool compact = false,
    Key revealKey = const ValueKey('reveal-next-hint'),
  }) => Container(
    key: const ValueKey('wooden-hint-sign'),
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
      compact ? 10 : 14,
      compact ? 5 : 8,
      compact ? 8 : 10,
      compact ? 4 : 10,
    ),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE9B9), Color(0xFFE9BC75)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF9B6338), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x332D2818),
          offset: Offset(0, 3),
          blurRadius: 5,
        ),
        BoxShadow(
          color: Color(0x99FFF5D7),
          offset: Offset(0, 1),
          blurRadius: 0,
          spreadRadius: -1,
        ),
      ],
    ),
    child: CustomPaint(
      painter: _HintWoodGrainPainter(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                size: 19,
                color: Color(0xFF765019),
              ),
              const SizedBox(width: 5),
              const Text(
                'ヒント',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.1,
                  color: Color(0xFF59391F),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (currentHints < 2 && !currentWon && !compact)
                TextButton(
                  key: revealKey,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 36),
                    foregroundColor: const Color(0xFF59391F),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    setState(() => currentHints++);
                    save();
                    onReveal?.call();
                  },
                  child: Text(currentHints == 0 ? 'もうひとつ' : '次のヒント'),
                ),
            ],
          ),
          Text(
            currentWord.genre,
            style: TextStyle(
              fontSize: compact ? 16 : 18,
              height: 1.25,
              color: Color(0xFF4B321F),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (currentHints >= 1)
            Text(
              currentWord.clue,
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                height: 1.3,
                color: Color(0xFF4B321F),
              ),
            ),
          if (currentHints >= 2)
            Text(
              '最初の文字は「${currentWord.text[0]}」',
              style: TextStyle(
                fontSize: compact ? 15 : 17,
                height: 1.3,
                color: Color(0xFF4B321F),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    ),
  );

  String get growthMessage => switch (progress.totalSolved) {
    0 => '小さな芽と、花の小道',
    1 => '若葉と花がひらきました',
    2 => '苗木が育ち、蝶が遊びに',
    3 => '花畑に、うさぎが仲間入り',
    4 || 5 => '小鳥の歌と、広がる木立',
    6 || 7 => '花の木に、蝶が舞います',
    _ => 'きつねも暮らす、豊かな森に',
  };

  void eraseLetter() {
    final letters = input.text.characters.toList();
    if (letters.isEmpty) return;
    final text = letters.take(letters.length - 1).join();
    input.text = text;
    touch();
    ForestAudio.play('key', progress.soundEnabled);
  }

  void addLetter(String letter) {
    if (currentWon ||
        revealing ||
        input.text.characters.length >= currentWord.text.length) {
      return;
    }
    input.text += letter;
    touch();
    ForestAudio.play('key', progress.soundEnabled);
  }

  void changeLast(KanaChange change) {
    if (input.text.isEmpty || currentWon || revealing) return;
    final letters = input.text.characters.toList();
    letters[letters.length - 1] = changeKana(letters.last, change);
    input.text = letters.join();
    touch();
    ForestAudio.play('key', progress.soundEnabled);
  }

  void finishReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !revealing) return;
      if (currentWon) ForestAudio.play('win', progress.soundEnabled);
      setState(() {
        revealing = false;
        celebrating =
            currentWon &&
            !progress.reduceMotion &&
            !WidgetsBinding
                .instance
                .platformDispatcher
                .accessibilityFeatures
                .disableAnimations;
      });
      if (celebrating) {
        celebrationTimer?.cancel();
        celebrationTimer = Timer(const Duration(milliseconds: 1100), () {
          if (mounted) setState(() => celebrating = false);
        });
      }
    });
  }

  Future<void> touch() async {
    if (!progress.hapticsEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } on MissingPluginException {
      // Unsupported platforms simply omit feedback.
    } on PlatformException {
      // Haptics are optional and must never block input.
    }
  }

  Widget puzzle(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final minimum =
          (progress.swipeKeyboard ? 500 : 440) +
          math.max(0.0, MediaQuery.textScalerOf(context).scale(1) - 1.2) * 370;
      if (bounds.maxHeight >= minimum) return puzzleContents(context);
      return SingleChildScrollView(
        key: const ValueKey('compact-puzzle-scroll'),
        child: SizedBox(
          height: minimum,
          child: puzzleContents(
            context,
            keyboardViewportHeight: bounds.maxHeight,
          ),
        ),
      );
    },
  );

  Widget puzzleHeading(BuildContext context, {bool compact = false}) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          invitation is StageSession
              ? 'ステージ ${(invitation! as StageSession).stage.id} ・ ${currentWord.text.length}文字'
              : invitation != null
              ? '招待のことば'
              : dailyMode
              ? '今日のことば'
              : '${currentWord.text.length}文字のことば',
          style: TextStyle(
            fontSize: compact ? 18 : 20,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (dailyMode)
          Text(
            '${progress.today.date.substring(5)} ・ ${currentWord.text.length}文字',
            style: TextStyle(
              fontSize: compact ? 14 : 16,
              height: 1.2,
              color: green,
            ),
          ),
      ],
    );
    final tools = Wrap(
      children: [
        TextButton(
          onPressed: () => showMeaning(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            textStyle: TextStyle(fontSize: compact ? 14 : 16),
          ),
          child: const Text('見かた'),
        ),
        TextButton(
          key: const ValueKey('open-puzzle-hints'),
          onPressed: () => showHints(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            textStyle: TextStyle(fontSize: compact ? 14 : 16),
          ),
          child: Text(invitation != null ? 'ヒントを見る' : 'ヒント'),
        ),
      ],
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, compact ? 0 : 2),
      child: MediaQuery.textScalerOf(context).scale(1) > 1.4
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, tools],
            )
          : Row(
              children: [
                Expanded(child: title),
                tools,
              ],
            ),
    );
  }

  Widget keyboardOptions({VoidCallback? onChanged}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final swipe in [true, false])
        Semantics(
          selected: progress.swipeKeyboard == swipe,
          child: ListTile(
            key: ValueKey(swipe ? 'keyboard-mode-swipe' : 'keyboard-mode-all'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            selected: progress.swipeKeyboard == swipe,
            selectedTileColor: const Color(0xFFE4EED6),
            title: swipe
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '横スワイプ式',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'おすすめ',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          color: Color(0xFF58724F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    '五十音すべて表示',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
            trailing: Icon(
              progress.swipeKeyboard == swipe
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: green,
            ),
            onTap: () {
              setState(() => progress.swipeKeyboard = swipe);
              save();
              onChanged?.call();
            },
          ),
        ),
    ],
  );
  void showKeyboardSettings(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, refresh) => AlertDialog(
        title: const Text('文字盤の表示方法'),
        scrollable: true,
        content: keyboardOptions(onChanged: () => refresh(() {})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('とじる'),
          ),
        ],
      ),
    ),
  );

  Widget inputActions(BuildContext context) {
    final erase = PressFeedback(
      enabled: input.text.isNotEmpty,
      child: OutlinedButton(
        key: const ValueKey('erase-letter'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          foregroundColor: const Color(0xFF294731),
          disabledForegroundColor: const Color(0xFF65675F),
          backgroundColor: const Color(0xFFEAF0DF),
          disabledBackgroundColor: const Color(0xFFE8E6DE),
          side: BorderSide(
            color: input.text.isEmpty ? const Color(0xFFBCBDB5) : green,
            width: input.text.isEmpty ? 1 : 2,
          ),
        ),
        onPressed: input.text.isEmpty ? null : eraseLetter,
        child: const Text('1文字けす'),
      ),
    );
    final answer = PressFeedback(
      enabled: canSubmit,
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          textStyle: const TextStyle(
            fontSize: 19,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: canSubmit ? submit : null,
        child: Text(
          canSubmit
              ? '答える'
              : 'あと${currentWord.text.length - input.text.characters.length}文字',
        ),
      ),
    );
    if (MediaQuery.textScalerOf(context).scale(1) > 1.4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [erase, const SizedBox(height: 6), answer],
      );
    }
    return Row(
      children: [
        SizedBox(width: 112, child: erase),
        const SizedBox(width: 8),
        Expanded(child: answer),
      ],
    );
  }

  /// Guess history compressed into the play screen: the screen itself never
  /// scrolls. Rows shrink as guesses accumulate, and in very long games the
  /// oldest rows are summarized in one line so the newest guesses —
  /// including the one being revealed — always stay visible.
  Widget historyArea({required bool tight}) {
    if (currentGuesses.isEmpty) {
      return const Center(
        key: ValueKey('history-area'),
        child: Text(
          'どんなことばかな？',
          style: TextStyle(fontSize: 18, color: Color(0xFF4C6547)),
        ),
      );
    }
    final length = currentWord.text.length;
    return LayoutBuilder(
      key: const ValueKey('history-area'),
      builder: (context, box) {
        const gap = 4.0;
        const naturalTile = 48.0;
        const minTile = 22.0;
        final tileGap = length > 4 ? 5.0 : 9.0;
        final count = currentGuesses.length;
        final avail = box.maxHeight - (tight ? 4 : 12) - gap;
        var tile = naturalTile;
        final fitTile = (avail / count - gap) / 1.08;
        if (fitTile < tile) tile = fitTile;
        var omitted = 0;
        var summarize = false;
        // Fixed line height for the summary, independent of text scale, so
        // the row budget below matches what is actually laid out.
        const summaryHeight = 24.0;
        if (tile < minTile) {
          tile = minTile;
          final rowHeight = minTile * 1.08 + gap;
          if (avail >= summaryHeight + rowHeight) {
            final rowsFit = ((avail - summaryHeight) / rowHeight).floor();
            omitted = count - rowsFit;
            if (omitted < 0) omitted = 0;
            if (omitted > count - 1) omitted = count - 1;
            summarize = omitted > 0;
          } else {
            // No room even for the summary line: keep only the newest row.
            omitted = count - 1;
          }
        }
        final boardWidth = tile * length + tileGap * (length - 1);
        Widget row(int index) {
          final guess = currentGuesses[index];
          // Each row is exactly one tile tall: the row number scales down
          // with the tiles instead of stretching the row under large text.
          return Padding(
            padding: const EdgeInsets.only(bottom: gap),
            child: SizedBox(
              height: tile * 1.08,
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: boardWidth,
                        child: LetterBoard(
                          key: ValueKey(
                            dailyMode
                                ? 'today-${progress.today.date}-$index'
                                : '${progress.solved}-$index',
                          ),
                          text: guess,
                          length: length,
                          marks: judge(currentWord.text, guess),
                          compact: true,
                          dense: true,
                          reveal: animatedGuess == index && revealing,
                          onRevealComplete: finishReveal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(12, tight ? 4 : 12, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (summarize)
                SizedBox(
                  height: summaryHeight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'まえの $omitted 回は、ここでは省略しています',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4C6547),
                      ),
                    ),
                  ),
                ),
              for (var i = omitted; i < count; i++) row(i),
            ],
          ),
        );
      },
    );
  }

  Widget puzzleContents(
    BuildContext context, {
    double? keyboardViewportHeight,
  }) => LayoutBuilder(
    builder: (context, viewport) {
      final length = currentWord.text.length;
      final keyboardHeight = keyboardViewportHeight ?? viewport.maxHeight;
      final tight =
          viewport.maxHeight < 620 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
          !progress.swipeKeyboard;
      return Stack(
        children: [
          const PuzzleBackdrop(),
          Column(
            children: [
              puzzleHeading(context, compact: tight),
              if (!currentWon && !revealing) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, tight ? 0 : 2),
                  child: hintCard(compact: tight),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, tight ? 0 : 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label:
                              '入力したことば、${input.text.isEmpty ? '空欄' : input.text}。あと${length - input.text.characters.length}文字',
                          liveRegion: true,
                          child: ExcludeSemantics(
                            child: LetterBoard(
                              key: const ValueKey('draft-board'),
                              text: input.text,
                              length: length,
                              active: true,
                              dense: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF8B9B78),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x223B3526),
                              offset: Offset(0, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: RabbitMascot(
                          key: const ValueKey('puzzle-companion'),
                          width: tight ? 44 : 54,
                          height: tight ? 42 : 52,
                          animateIdle: false,
                          mood: currentGuesses.isEmpty
                              ? RabbitMood.idle
                              : RabbitMood.greeting,
                          event: currentGuesses.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(child: historyArea(tight: tight)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  12,
                  tight ? 0 : 2,
                  12,
                  tight ? 0 : 2,
                ),
                constraints: currentWon
                    ? BoxConstraints(maxHeight: viewport.maxHeight * .70)
                    : null,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFBED), Color(0xFFF5EBD9)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(color: const Color(0xFFCDDAC4)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (revealing)
                        const Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                            'ことばを見てみましょう…',
                            style: TextStyle(fontSize: 19),
                          ),
                        )
                      else if (currentWon) ...[
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: .92, end: 1),
                          duration: Duration(
                            milliseconds:
                                MediaQuery.disableAnimationsOf(context)
                                ? 0
                                : 360,
                          ),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) =>
                              Transform.scale(scale: value, child: child),
                          child: Row(
                            children: [
                              RabbitMascot(
                                key: ValueKey('happy-${progress.totalSolved}'),
                                mood: RabbitMood.happy,
                                event: progress.totalSolved,
                                width: 112,
                                height: 104,
                                animateIdle: false,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Semantics(
                                  liveRegion: true,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dailyMode
                                            ? progress.lastReward == 30
                                                  ? '今日のことばクリア！ +30コイン'
                                                  : '本日はクリア済み'
                                            : 'せいかい！',
                                        style: TextStyle(
                                          fontSize: dailyMode ? 21 : 27,
                                          color: green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        invitation is StageSession
                                            ? '小道に星が輝きました！'
                                            : invitation != null
                                            ? 'ことばの招待状、届きました！'
                                            : growthMessage,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      if (invitation == null &&
                                          progress.lastReward > 0 &&
                                          !dailyMode)
                                        Text(
                                          '+${progress.lastReward} コイン',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: green,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '今回は${currentGuesses.length}回で正解！',
                          key: const ValueKey('clear-attempts'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: green,
                          ),
                        ),
                        if (invitation is StageSession)
                          StageStars(
                            key: const ValueKey('stage-clear-stars'),
                            count: StageJourney.rating(currentGuesses.length),
                            animate: true,
                          ),
                        if (invitation is StageSession)
                          stageRewardOffer(invitation! as StageSession),
                        if (invitation == null &&
                            progress
                                    .statistics(currentWord.text.length)
                                    .averageAttempts !=
                                null)
                          Text(
                            'あなたの${currentWord.text.length}文字の平均 ${progress.statistics(currentWord.text.length).averageAttempts!.toStringAsFixed(1)}回',
                            key: const ValueKey('clear-personal-average'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              color: Color(0xFF4F624C),
                            ),
                          ),
                        if (invitation == null && progress.lastDailyBonus)
                          const Text(
                            '今日の目標たっせい！ ＋30コイン',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF765019),
                            ),
                          ),
                        if (!celebrating)
                          button(
                            invitation is StageSession
                                ? 'そのまま続ける'
                                : invitation != null
                                ? '招待状にもどる'
                                : dailyMode
                                ? '通常の問題へ'
                                : 'つぎの問題',
                            next,
                            primary: true,
                          ),
                        if (invitation == null)
                          Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              TextButton(
                                key: const ValueKey('show-records'),
                                onPressed: () => showRecords(context),
                                child: const Text('わたしの記録'),
                              ),
                              TextButton(
                                onPressed: () => go('わたしの森'),
                                child: const Text('育った森を見る'),
                              ),
                            ],
                          ),
                      ] else ...[
                        KanaKeyboard(
                          swipe: progress.swipeKeyboard,
                          showSwipeGuide:
                              invitation is StageSession &&
                              (invitation! as StageSession).stage.id == 1,
                          onDisplaySettings: () =>
                              showKeyboardSettings(context),
                          maxTableHeight: progress.swipeKeyboard
                              ? (keyboardHeight - (tight ? 380 : 410))
                                    .clamp(tight ? 150 : 180, 380)
                                    .toDouble()
                              : (MediaQuery.textScalerOf(context).scale(1) > 1.4
                                    ? keyboardHeight >= 779
                                          ? (keyboardHeight - 330)
                                                .clamp(120, 620)
                                                .toDouble()
                                          : 144
                                    : (keyboardHeight -
                                              (keyboardHeight >= 779
                                                  ? 385
                                                  : 344))
                                          .clamp(120, 620)
                                          .toDouble()),
                          text: input.text,
                          full: input.text.characters.length >= length,
                          onLetter: addLetter,
                          onChange: changeLast,
                        ),
                        const SizedBox(height: 4),
                        inputActions(context),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (celebrating) const Positioned.fill(child: SuccessPetals()),
        ],
      );
    },
  );
  void showRecords(BuildContext context) {
    final performance = progress.performance;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .86,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'わたしの記録',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: green,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('とじる'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  key: const ValueKey('records-list'),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    panel([
                      Row(
                        children: [
                          const ForestItemArt(
                            item: 'tulip',
                            width: 66,
                            height: 80,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'ひとつずつ、育つ記録',
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      recordValue('累計正解数', '${performance.lifetimeClears}問'),
                      recordValue(
                        '平均挑戦回数',
                        performance.overall.averageAttempts == null
                            ? '—'
                            : '${performance.overall.averageAttempts!.toStringAsFixed(1)}回',
                      ),
                      recordValue('現在の連続正解', '${performance.overall.streak}問'),
                      recordValue(
                        '最高の連続正解',
                        '${performance.overall.bestStreak}問',
                      ),
                    ]),
                    const SizedBox(height: 8),
                    const Text(
                      '平均・連続正解は、記録機能の追加後から。通常と「今日のことば」を含みます。',
                      style: TextStyle(fontSize: 17),
                    ),
                    for (final length in [3, 4, 5])
                      panel([
                        heading('$length文字の記録'),
                        const SizedBox(height: 8),
                        recordValue(
                          '累計正解数',
                          '${progress.statistics(length).clears}問',
                        ),
                        recordValue(
                          '平均挑戦回数',
                          progress.statistics(length).averageAttempts == null
                              ? '—'
                              : '${progress.statistics(length).averageAttempts!.toStringAsFixed(1)}回',
                        ),
                        recordValue(
                          '連続正解数',
                          '${progress.statistics(length).streak}問',
                        ),
                        recordValue(
                          '最高の連続正解',
                          '${performance.forLength(length).bestStreak}問',
                        ),
                      ]),
                    const Text(
                      '回数制限のない遊びなので、考え直しても、お休みしても、連続正解は途切れません。',
                      style: TextStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 16),
                    heading('今日のことばの記録'),
                    recordValue(
                      'クリアした日',
                      '${performance.dailyClearDates.length}日',
                    ),
                    Text(
                      performance.dailyClearDates.contains(progress.today.date)
                          ? '本日はクリア済み'
                          : '今日はこれから。ゆっくり楽しみましょう。',
                      style: const TextStyle(fontSize: 18, color: green),
                    ),
                    if (performance.dailyClearDates.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('正解した日を、ここに残します。'),
                      ),
                    for (final date in performance.dailyDatesNewestFirst.take(
                      14,
                    ))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '$date　${performance.dailyRecord(date) == null ? 'クリア済み（回数の記録なし）' : '${performance.dailyRecord(date)!.attempts}回で正解'}',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    const SizedBox(height: 16),
                    heading('最近の解答記録'),
                    if (progress.records.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('これからの正解を、ひとつずつ記録します。'),
                      ),
                    for (final record in progress.records.reversed.take(20))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${record.word}　${record.attempts}回で正解',
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: green,
                              ),
                            ),
                            Text(
                              '${record.date}・${record.length}文字${record.source == 'daily' ? '・今日のことば' : ''}',
                              style: const TextStyle(fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget recordValue(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 19))),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
        ),
      ],
    ),
  );

  ForestScene forestArtwork(BuildContext screenContext, {required Key key}) =>
      ForestScene(
        key: key,
        area: firstForestArea,
        growth: progress.totalSolved,
        friends: progress.forestAnimalsFor(firstForestArea.id),
        items: progress.ownedItems,
        editable: true,
        movingItem: movingForestItem,
        itemPositions: {
          ...progress.forestAreaProgress(firstForestArea.id).itemPositions,
          ...draftForestPositions,
        },
        itemAppearances: {
          ...progress.forestAreaProgress(firstForestArea.id).itemAppearances,
          ...draftForestAppearances,
        },
        onItemMoved: moveForestItem,
        onItemTapped: (id) => showForestItemMenu(screenContext, id),
      );

  Widget forestPanorama() => LayoutBuilder(
    builder: (context, viewport) {
      final aspect = firstForestArea.aspectRatio;
      final width = math.max(viewport.maxWidth, viewport.maxHeight * aspect);
      final height = width / aspect;
      final canPan = movingForestItem == null;
      if (!forestViewInitialized) {
        forestViewInitialized = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !forestFullscreen) return;
          forestViewTransform.value = Matrix4.identity()
            ..translateByDouble(
              (viewport.maxWidth - width) / 2,
              (viewport.maxHeight - height) / 2,
              0,
              1,
            );
        });
      }
      return SizedBox.expand(
        child: InteractiveViewer(
          key: const ValueKey('forest-fullscreen-viewer'),
          transformationController: forestViewTransform,
          constrained: false,
          alignment: Alignment.center,
          minScale: 1,
          maxScale: 3,
          boundaryMargin: const EdgeInsets.all(48),
          panEnabled: canPan,
          scaleEnabled: canPan,
          child: SizedBox(
            width: width,
            height: height,
            child: forestArtwork(
              context,
              key: const ValueKey('my-forest-scene-fullscreen'),
            ),
          ),
        ),
      );
    },
  );

  List<Widget> forest(BuildContext screenContext) => [
    heading('わたしの森'),
    Text(
      ForestScene.stage(progress.totalSolved),
      style: const TextStyle(fontSize: 17, color: green),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        movingForestItem == null
            ? '飾りをタップすると、移動・収納・売却ができます。'
            : '移動中です。飾りをドラッグして「ここに置く」を押してください。',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, color: Color(0xFF405A3D)),
      ),
    ),
    const SizedBox(height: 8),
    Semantics(
      button: true,
      label: '森を大きく見る',
      child: GestureDetector(
        key: const ValueKey('open-forest-fullscreen'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          forestViewInitialized = false;
          forestViewTransform.value = Matrix4.identity();
          forestFullscreen = true;
        }),
        child: forestArtwork(
          screenContext,
          key: const ValueKey('my-forest-scene'),
        ),
      ),
    ),
    const SizedBox(height: 8),
    forestDecorationShelf(),
    const SizedBox(height: 8),
    ForestShopHouse(onTap: () => go('森のお店')),
    const SizedBox(height: 12),
    const Text(
      '森の小さなお店をタップして、飾りを選びましょう。',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: green),
    ),
    const SizedBox(height: 12),
    wallet(),
    Builder(builder: (context) => button('わたしの記録', () => showRecords(context))),
    panel([
      heading('${progress.totalSolved}個のことばを発見'),
      const SizedBox(height: 10),
      Text(
        progress.totalSolved < 3
            ? '3問で花が咲き、うさぎが遊びに来ます。'
            : progress.totalSolved < 6
            ? '6問で大きな木に。森は少しずつ育ちます。'
            : progress.totalSolved < 8
            ? '8問できつねと小鳥が仲間入り。'
            : '木も花も、森の仲間も。あなたのことばで育ちました。',
      ),
    ]),
    button('ことばを探しにいく', startNormal, primary: true),
  ];

  Widget forestDecorationShelf() {
    final stored = forestItems
        .where(
          (item) =>
              progress.ownedItems.contains(item.id) &&
              !progress.itemPositions.containsKey(item.id),
        )
        .toList();
    return DragTarget<String>(
      key: const ValueKey('my-forest-storage'),
      onWillAcceptWithDetails: (details) =>
          progress.itemPositions.containsKey(details.data),
      onAcceptWithDetails: (details) => storeForestItem(details.data),
      builder: (context, candidates, rejected) => Container(
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? const Color(0xFFEAF3D9)
              : const Color(0xFFF8F1DD).withValues(alpha: .94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB8955D), width: 1.5),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 82,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, color: green, size: 28),
                  SizedBox(height: 3),
                  Text(
                    '飾り置き場',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: stored.isEmpty
                  ? const Text(
                      '飾りをタップして「しまう」を選べます',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: green),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final item in stored)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: LongPressDraggable<String>(
                                key: ValueKey('forest-storage-item-${item.id}'),
                                data: item.id,
                                maxSimultaneousDrags: 1,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ForestItemArt(
                                        item: item.id,
                                        width: 62,
                                        height: 68,
                                      ),
                                      Text(item.name),
                                    ],
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: .35,
                                  child: _storedItemTile(item),
                                ),
                                child: _storedItemTile(item),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storedItemTile(ForestItem item) => SizedBox(
    width: 72,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ForestItemArt(item: item.id, width: 52, height: 58),
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  List<Widget> shopPage() => [
    heading('森の小さなお店'),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RabbitMascot(
          key: const ValueKey('shop-mascot'),
          width: 68,
          height: 88,
          mood: shopThanks > 0 ? RabbitMood.bow : RabbitMood.idle,
          event: shopThanks,
        ),
        const SizedBox(width: 8),
        const Flexible(
          child: Text(
            '森にぴったりの仲間を選んでね',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: green,
            ),
          ),
        ),
      ],
    ),
    wallet(),
    shopCarousel(),
    const Text(
      '初めて解いたことばは10コイン。今日の目標達成で30コインがもらえます。',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16),
    ),
    adCoinOffer(),
  ];

  Widget adCoinOffer() => ValueListenableBuilder<bool>(
    valueListenable: MonetizationAds.rewardReady,
    builder: (context, ready, _) {
      if (!MonetizationAds.configuredForBuild) return const SizedBox.shrink();
      final claimed = adCoinRewardClaimed;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: panel([
          const Text(
            '森のお手伝い',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const Text(
            '動画を見ると、1日1回だけ10コインのお礼がもらえます。見るかどうかは自由です。',
            style: TextStyle(fontSize: 17, height: 1.4),
          ),
          button(
            claimed
                ? '今日は受け取り済み'
                : adRewardInProgress
                ? '動画を見ています…'
                : ready
                ? '動画を見て ＋10コイン'
                : '動画を準備しています…',
            ready && !claimed && !adRewardInProgress ? watchAdForCoins : null,
            primary: true,
          ),
        ]),
      );
    },
  );

  Widget stageRewardOffer(StageSession session) {
    final now = DateTime.now();
    final stageId = session.stage.id;
    final date = Progress.dayKey(now);
    final amount = session.clearRewardDate == date
        ? session.clearRewardAmount
        : 0;
    final eligibleForAd =
        amount > 0 && !progress.stageAdRewardClaimed(stageId, now);

    return Container(
      key: const ValueKey('stage-clear-reward'),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5D8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6B66D), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24714924),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            amount > 0 ? 'クリア報酬　＋$amount コイン' : '今日はこのステージの報酬を受け取り済みです',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF62421F),
            ),
          ),
          if (eligibleForAd) ...[
            const SizedBox(height: 4),
            Text(
              '広告を最後まで見ると、追加 ＋$amount コイン',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF62421F)),
            ),
            Text(
              '報酬は合計 ＋${amount * 2} コイン',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF765A35)),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: MonetizationAds.rewardReady,
              builder: (context, ready, _) {
                final enabled =
                    MonetizationAds.configuredForBuild &&
                    ready &&
                    !stageAdRewardInProgress &&
                    eligibleForAd;
                final label = !MonetizationAds.configuredForBuild
                    ? '広告は現在利用できません'
                    : stageAdRewardInProgress
                    ? '動画を見ています…'
                    : ready
                    ? '広告を見てコイン2倍'
                    : '広告を準備しています…';
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('stage-reward-ad'),
                    onPressed: enabled
                        ? () => watchAdForStageReward(session)
                        : null,
                    icon: const Icon(Icons.ondemand_video),
                    label: Text(label),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ] else if (progress.stageAdRewardClaimed(stageId, now))
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '広告ボーナスは受け取り済みです',
                style: TextStyle(fontSize: 15, color: Color(0xFF62421F)),
              ),
            ),
        ],
      ),
    );
  }

  void turnShop(int index) {
    if (!shopPages.hasClients || index < 0 || index >= forestItems.length) {
      return;
    }
    if (progress.reduceMotion ||
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations) {
      shopPages.jumpToPage(index);
    } else {
      shopPages.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Widget shopCarousel() => Builder(
    builder: (context) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final narrow = MediaQuery.sizeOf(context).width < 360;
      return Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            '左右にめくって、好きな仲間を見つけよう',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(
            height: 440 + (scale - 1).clamp(0, 2) * 260 + (narrow ? 64 : 0),
            child: PageView.builder(
              key: const ValueKey('shop-carousel'),
              controller: shopPages,
              itemCount: forestItems.length,
              onPageChanged: (index) {
                setState(() => shopIndex = index);
                ForestAudio.play('key', progress.soundEnabled);
              },
              itemBuilder: (context, index) => AnimatedScale(
                scale: index == shopIndex ? 1 : .95,
                duration: Duration(
                  milliseconds: MediaQuery.disableAnimationsOf(context)
                      ? 0
                      : 180,
                ),
                child: shopCard(context, forestItems[index]),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                key: const ValueKey('shop-previous'),
                onPressed: shopIndex > 0 ? () => turnShop(shopIndex - 1) : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('前へ'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              Semantics(
                liveRegion: true,
                label:
                    '${shopIndex + 1} / ${forestItems.length}、${forestItems[shopIndex].name}',
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < forestItems.length; i++)
                        AnimatedContainer(
                          duration: Duration(
                            milliseconds:
                                MediaQuery.disableAnimationsOf(context)
                                ? 0
                                : 180,
                          ),
                          width: i == shopIndex ? 16 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == shopIndex
                                ? green
                                : const Color(0xFFC8D1BC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('shop-next'),
                onPressed: shopIndex < forestItems.length - 1
                    ? () => turnShop(shopIndex + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('次へ'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );
    },
  );
  Widget shopCard(BuildContext context, ForestItem item) {
    final owned = progress.ownedItems.contains(item.id);
    final description = switch (item.id) {
      'tulip' => '小道のそばに、桃色と黄色の3輪。',
      'mushroom' => '草かげに、大小ふたつの小さな傘。',
      'sunflower' => 'おひさま色の大きな花が、ぱっと一輪。',
      'butterfly' => '水色のチョウが、木々の間をふわり。',
      _ => 'やさしい桜色の木と、足もとの花びら。',
    };
    return Container(
      key: ValueKey('shop-${item.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFDF6), Color(0xFFF4EADB)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD9C8AA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C705237),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF2F3DE), Color(0xFFDDE9D4)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFB9CBA9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F4C623F),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: ForestItemArt(item: item.id, width: 136, height: 156),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CoinGlyph(),
                const SizedBox(width: 6),
                Text(
                  '${item.price} コイン',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF67471E),
                  ),
                ),
              ],
            ),
            button(
              owned
                  ? '購入済み ・ 森にいます'
                  : progress.coins >= item.price
                  ? '森に迎える'
                  : 'あと${item.price - progress.coins}コイン必要',
              owned || progress.coins < item.price
                  ? null
                  : () => confirmBuy(context, item),
              primary: true,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> help() => [
    heading('ひらがなを押して、ことばをつくろう'),
    panel([
      const Text('「さくら」が答えのとき、「くらげ」と入れると…'),
      const SizedBox(height: 14),
      LetterBoard(text: 'くらげ', length: 3, marks: judge('さくら', 'くらげ')),
      const SizedBox(height: 14),
      const Text('◎ 文字も場所も正解\n△ 文字はあるけれど、場所が違う\n× ない文字・余った文字'),
    ]),
    panel([
      const Text('場所を入れかえて、もう一度。全部 ◎ で正解です。'),
      const SizedBox(height: 14),
      LetterBoard(text: 'さくら', length: 3, marks: judge('さくら', 'さくら')),
    ]),
    panel([
      const Text(
        '一覧のひらがなを押すと、マスに順番に入ります。小さい画面では一覧を上下に動かせます。濁点・半濁点・小文字は最後の文字を変えます。「1文字けす」で戻せます。\n\n時間も回数も制限はありません。\n\nヒントは「ジャンル → 特徴 → 最初の文字」の順に見られます。\n\n同じ文字は、答えにある数だけ ◎ や △ になります。小さい「ゃ」「っ」や「ー」も1文字です。カタカナはひらがなに直します。辞書にないことばも試せます。',
      ),
    ]),
    button('あそんでみる', startNormal, primary: true),
  ];

  List<Widget> legalPage(List<LegalSection> sections) => [
    for (final section in sections)
      panel([
        Text(
          section.heading,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: green,
          ),
        ),
        const SizedBox(height: 8),
        Text(section.body, style: const TextStyle(fontSize: 18, height: 1.7)),
      ]),
    Text(
      '最終更新日：${legalLastUpdated.isEmpty ? legalUnset : legalLastUpdated}',
      style: const TextStyle(fontSize: 16, color: Color(0xFF64755F)),
    ),
  ];

  Widget legalInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 17, color: Color(0xFF64755F)),
        ),
        SelectableText(
          value.isEmpty ? legalUnset : value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  List<Widget> contactPage() => [
    heading('お問い合わせ'),
    panel([
      const Text(
        '本アプリへのご意見・ご質問をお寄せください。',
        style: TextStyle(fontSize: 18, height: 1.7),
      ),
      const SizedBox(height: 12),
      legalInfoRow('運営者', legalOperatorName),
      legalInfoRow('メール', legalContactEmail),
      if (legalOperatorName.isEmpty || legalContactEmail.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            '※ 公開前に、運営者名と連絡先を設定してください。',
            style: TextStyle(fontSize: 16, color: Color(0xFF8A6D3B)),
          ),
        ),
    ]),
  ];

  Widget screen(BuildContext context) => PopScope(
    canPop: page == 'ホーム' && departingLength == null,
    onPopInvokedWithResult: (didPop, result) {
      if (forestFullscreen) {
        setState(() {
          forestFullscreen = false;
          forestViewInitialized = false;
        });
        return;
      }
      if (departingLength != null) {
        setState(() => departingLength = null);
        return;
      }
      if (!didPop) goBack();
    },
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (page == 'わたしの森')
          const ColoredBox(color: Color(0xFFE8F0D8))
        else
          FantasyBackdrop(
            asset: switch (page) {
              'ホーム' => 'assets/art/home-glade.png',
              'ステージマップ' => 'assets/art/cartoon-map.png',
              'わたしの森' => 'assets/art/forest-garden.png',
              '森のお店' => 'assets/art/forest-garden.png',
              _ => 'assets/art/cartoon-home.png',
            },
            veil: page == 'ホーム'
                ? .24
                : page == 'パズル'
                ? .72
                : page == 'わたしの森'
                ? .22
                : .35,
            // Every destination gets the same gentle woodland ambience. The
            // backdrop's ticker is stopped by TickerMode/lifecycle/reduce-motion.
            animate: page != 'パズル',
          ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: cream.withValues(alpha: .88),
            automaticallyImplyLeading: false,
            centerTitle: true,
            toolbarHeight: 56,
            leadingWidth: MediaQuery.textScalerOf(context).scale(1) > 1.4
                ? 148
                : 120,
            leading: page == 'ホーム'
                ? IconButton(
                    key: const ValueKey('home-settings'),
                    onPressed: () => go('設定'),
                    icon: const Icon(Icons.settings, size: 28),
                    color: green,
                    tooltip: '設定',
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  )
                : forestFullscreen
                ? IconButton(
                    key: const ValueKey('close-forest-fullscreen'),
                    tooltip: '森の画面に戻る',
                    onPressed: () => setState(() {
                      forestFullscreen = false;
                      forestViewInitialized = false;
                    }),
                    icon: const Icon(Icons.chevron_left),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  )
                : Row(
                    children: [
                      IconButton(
                        key: const ValueKey('previous-page'),
                        tooltip: '前の画面に戻る',
                        onPressed: goBack,
                        icon: const Icon(Icons.chevron_left),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          onPressed: () => go('ホーム'),
                          child: const Text(
                            'ホーム',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
            title:
                MediaQuery.sizeOf(context).width < 360 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.4
                ? const SizedBox.shrink()
                : Text(
                    page == 'ホーム'
                        ? ''
                        : page == 'パズル'
                        ? 'パズル'
                        : page == 'わたしの森'
                        ? (forestFullscreen ? 'わたしの森' : '森')
                        : page,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Center(child: CoinBadge(coins: progress.coins)),
              ),
            ],
          ),
          body: !ready
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        children: [
                          if (storageError != null)
                            MaterialBanner(
                              content: Text(storageError!),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    save();
                                    saveJourney();
                                  },
                                  child: const Text('再保存'),
                                ),
                              ],
                            ),
                          Expanded(
                            child: page == 'わたしの森' && forestFullscreen
                                ? forestPanorama()
                                : page == 'パズル'
                                ? puzzle(context)
                                : page == 'ステージマップ'
                                ? ForestStageMap(
                                    journey: journey,
                                    onSelect: beginStage,
                                    onNormalModes: () => go('文字数をえらぶ'),
                                    reduceMotion: progress.reduceMotion,
                                  )
                                : ListView(
                                    // Keep each page's scroll position separate so a
                                    // scrolled home list does not offset other pages.
                                    // The forest page keeps its own controller as-is.
                                    key: page == 'わたしの森'
                                        ? null
                                        : PageStorageKey<String>(page),
                                    controller: page == 'わたしの森'
                                        ? forestScroll
                                        : null,
                                    physics:
                                        page == 'わたしの森' &&
                                            movingForestItem != null
                                        ? const NeverScrollableScrollPhysics()
                                        : null,
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      8,
                                      24,
                                      24,
                                    ),
                                    children: switch (page) {
                                      'ことばの招待状' => [
                                        InvitationPanel(onPlay: playInvitation),
                                      ],
                                      '文字数をえらぶ' => modePicker(),
                                      'わたしの森' => forest(context),
                                      '森のお店' => shopPage(),
                                      'あそびかた' => help(),
                                      '設定' => [
                                        heading('読みやすさと動き'),
                                        panel([
                                          const Text(
                                            '文字盤の表示方法',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          keyboardOptions(),
                                          const SizedBox(height: 16),

                                          const Text(
                                            '文字の大きさ',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: SegmentedButton<bool>(
                                              segments: const [
                                                ButtonSegment(
                                                  value: false,
                                                  label: Text('標準'),
                                                ),
                                                ButtonSegment(
                                                  value: true,
                                                  label: Text('大きめ'),
                                                ),
                                              ],
                                              selected: {progress.largeText},
                                              style: const ButtonStyle(
                                                minimumSize:
                                                    WidgetStatePropertyAll(
                                                      Size(48, 56),
                                                    ),
                                                textStyle:
                                                    WidgetStatePropertyAll(
                                                      TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                              ),
                                              onSelectionChanged: (value) {
                                                setState(
                                                  () => progress.largeText =
                                                      value.first,
                                                );
                                                save();
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text('ボタンの振動'),
                                            subtitle: const Text(
                                              '小さな振動で操作をお知らせ',
                                            ),
                                            value: progress.hapticsEnabled,
                                            onChanged: (value) {
                                              setState(
                                                () => progress.hapticsEnabled =
                                                    value,
                                              );
                                              save();
                                            },
                                          ),
                                          SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text('効果音'),
                                            subtitle: const Text('小さく、やさしい音'),
                                            value: progress.soundEnabled,
                                            onChanged: (value) {
                                              setState(
                                                () => progress.soundEnabled =
                                                    value,
                                              );
                                              if (!value) ForestAudio.stop();
                                              save();
                                            },
                                          ),
                                          SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text('BGM'),
                                            subtitle: const Text(
                                              '画面に合わせた音楽を流します',
                                            ),
                                            value: progress.musicEnabled,
                                            onChanged: (value) {
                                              setState(
                                                () => progress.musicEnabled =
                                                    value,
                                              );
                                              syncMusic();
                                              save();
                                            },
                                          ),
                                          button(
                                            '効果音を試す',
                                            progress.soundEnabled
                                                ? () => showSoundTest(context)
                                                : null,
                                          ),
                                          SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text('動きを減らす'),
                                            subtitle: const Text(
                                              '森の揺れや蝶の動きを止めます。',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            value: progress.reduceMotion,
                                            onChanged: (value) {
                                              setState(
                                                () => progress.reduceMotion =
                                                    value,
                                              );
                                              save();
                                            },
                                          ),
                                          const Text(
                                            '端末の「アニメーションを減らす」設定にも対応します。',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          const Text('進み具合は、この端末に自動保存します。'),
                                        ]),
                                        const SizedBox(height: 10),
                                        heading('規約とサポート'),
                                        panel([
                                          button(
                                            'プライバシーポリシー',
                                            () => go('プライバシーポリシー'),
                                          ),
                                          button('利用規約', () => go('利用規約')),
                                          button('お問い合わせ', () => go('お問い合わせ')),
                                          ValueListenableBuilder<bool>(
                                            valueListenable: MonetizationAds
                                                .privacyOptionsRequired,
                                            builder: (context, required, _) =>
                                                required
                                                ? button(
                                                    '広告のプライバシー設定',
                                                    MonetizationAds
                                                        .showPrivacyOptions,
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ]),
                                      ],
                                      'プライバシーポリシー' => legalPage(
                                        privacyPolicySections,
                                      ),
                                      '利用規約' => legalPage(termsSections),
                                      'お問い合わせ' => contactPage(),
                                      _ => home(context),
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          bottomNavigationBar: movingForestItem == null
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: cancelForestMove,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 56),
                          ),
                          child: const Text(
                            'やめる',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          key: const ValueKey('confirm-forest-move'),
                          onPressed: finishForestMove,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 56),
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text(
                            'ここに置く',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (launchingStage case final stageId?)
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('stage-intro-$stageId'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                curve: Curves.linear,
                onEnd: () {
                  finishStageIntro(stageId);
                },
                builder: (context, value, child) {
                  final fade = progress.reduceMotion ? .04 : .12;
                  final introOpacity = value < fade
                      ? Curves.easeOut.transform(value / fade)
                      : 1.0;
                  return AnimatedOpacity(
                    opacity: stageIntroRevealing ? 0 : introOpacity,
                    duration: stageIntroRevealing
                        ? const Duration(milliseconds: 180)
                        : Duration.zero,
                    onEnd: () {
                      if (stageIntroRevealing && launchingStage == stageId) {
                        setState(() {
                          launchingStage = null;
                          stageIntroRevealing = false;
                        });
                      }
                    },
                    child: child,
                  );
                },
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF7EADF),
                        Color(0xFFEED8D9),
                        Color(0xFFF9EED7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Positioned(
                          top: 42,
                          left: 38,
                          child: Icon(
                            Icons.local_florist_rounded,
                            color: Color(0xFFC98291),
                            size: 28,
                          ),
                        ),
                        const Positioned(
                          right: 42,
                          bottom: 48,
                          child: Icon(
                            Icons.spa_rounded,
                            color: Color(0xFF8F9C65),
                            size: 30,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFFCF6), Color(0xFFF4E7D8)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0xFFD4AF72),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x443D2C23),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ステージ $stageId',
                                style: const TextStyle(
                                  color: Color(0xFF684638),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '今日も、ゆっくりことば探し。',
                                style: TextStyle(
                                  color: Color(0xFF8A6756),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    scaffoldMessengerKey: messenger,
    debugShowCheckedModeBanner: false,
    title: 'ことばの森',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        primary: green,
        surface: cream,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontSize: 20,
          height: 1.6,
          color: Color(0xFF293D30),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontFamily: 'ZenMaru',
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          disabledBackgroundColor: const Color(0xFFE2E6D9),
          disabledForegroundColor: const Color(0xFF4C5F49),
          minimumSize: const Size(48, 58),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'ZenMaru',
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 56),
          backgroundColor: const Color(0xFFEDF2E5),
          foregroundColor: green,
          side: const BorderSide(color: green, width: 1.4),
          textStyle: const TextStyle(
            fontFamily: 'ZenMaru',
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
      ),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations:
            progress.reduceMotion || MediaQuery.disableAnimationsOf(context),
        textScaler: TextScaler.linear(
          MediaQuery.textScalerOf(context).scale(1) *
              (progress.largeText ? 1.2 : 1),
        ),
      ),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Stack(
        children: [
          AnimatedSwitcher(
            duration: Duration(
              milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 450,
            ),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: titleActive
                ? PopScope(
                    key: const ValueKey('title-screen'),
                    canPop: !showingWelcome,
                    onPopInvokedWithResult: (didPop, result) {
                      if (!didPop && showingWelcome) {
                        setState(() => showingWelcome = false);
                      }
                    },
                    child: ForestTitleScreen(
                      ready: ready,
                      welcome: showingWelcome,
                      onStart: startFromTitle,
                      onWelcomeDone: finishWelcome,
                    ),
                  )
                : KeyedSubtree(
                    key: const ValueKey('home-screen'),
                    child: Stack(
                      children: [
                        screen(context),
                        if (departingLength != null)
                          Positioned.fill(
                            child: RabbitSendoff(
                              key: const ValueKey('sendoff-overlay'),
                              onComplete: completeSendoff,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          if (petaling)
            Positioned.fill(
              child: PetalTransition(
                key: const ValueKey('petal-wipe'),
                onCovered: onPetalsCovered,
                onDone: onPetalsDone,
              ),
            ),
        ],
      ),
    ),
  );
}

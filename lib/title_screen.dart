import 'storybook_surface.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'press_feedback.dart';
import 'letter_board.dart' show forestGreen;
import 'fantasy_backdrop.dart';

/// Uses the same independently repainted woodland and articulated mascot as home.
class ForestTitleScreen extends StatefulWidget {
  final bool ready, welcome;
  final VoidCallback onStart, onWelcomeDone;
  const ForestTitleScreen({
    super.key,
    required this.ready,
    required this.welcome,
    required this.onStart,
    required this.onWelcomeDone,
  });

  @override
  State<ForestTitleScreen> createState() => _ForestTitleScreenState();
}

class _ForestTitleScreenState extends State<ForestTitleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController treeWind = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();
  bool leaping = false;
  int leapEvent = 0;

  void syncWind() {
    final enabled =
        widget.ready &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled && !treeWind.isAnimating) {
      treeWind.repeat();
    } else if (!enabled && treeWind.isAnimating) {
      treeWind.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncWind();
  }

  @override
  void didUpdateWidget(ForestTitleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncWind();
  }

  @override
  void dispose() {
    treeWind.dispose();
    super.dispose();
  }

  // Tap anywhere to begin; the petal wipe (handled by the app) takes over.
  void start() {
    if (!widget.ready || leaping) return;
    setState(() {
      leaping = true;
      leapEvent++;
    });
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF6EA),
    body: GestureDetector(
      // Tap anywhere on the title (not the welcome card) to begin.
      behavior: HitTestBehavior.opaque,
      onTap: widget.welcome ? null : start,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FantasyBackdrop(
            asset: 'assets/art/title-portal.png',
            alignment: Alignment.center,
            veil: widget.welcome ? .56 : .12,
            animate: widget.ready,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, size) => Align(
                  alignment: const Alignment(0, .62),
                  child: AnimatedBuilder(
                    animation: treeWind,
                    builder: (context, child) => Transform.rotate(
                      alignment: Alignment.bottomCenter,
                      angle: treeWind.isAnimating
                          ? math.sin(treeWind.value * math.pi * 2) * .009
                          : 0,
                      child: child,
                    ),
                    child: Image.asset(
                      'assets/art/magic-tree.png',
                      width: size.maxWidth * .93,
                      height: size.maxHeight * .72,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                key: ValueKey(
                  widget.welcome ? 'welcome-scroll' : 'title-scroll',
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewport.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.welcome
                              ? [
                                  const Text(
                                    'ことばの森へようこそ！',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'ZenMaru',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: forestGreen,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFFFFF7D6),
                                          blurRadius: 14,
                                        ),
                                        Shadow(
                                          color: Color(0xFFFFF7D6),
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFDF7),
                                      borderRadius: BorderRadius.circular(26),
                                      border: Border.all(
                                        color: const Color(0xFFD9DFC9),
                                      ),
                                    ),
                                    child: const Text(
                                      'このゲームは、ひらがなのことばを見つけながら、小さな森を育てるゲームです。\n\n'
                                      '目が疲れたときは、無理せずひと休みしてくださいね。\n\n'
                                      '自分のペースで、ゆっくり楽しみましょう。',
                                      key: ValueKey('welcome-message'),
                                      style: TextStyle(
                                        fontSize: 20,
                                        height: 1.65,
                                        color: Color(0xFF293D30),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: PressFeedback(
                                      child: FilledButton(
                                        key: const ValueKey('welcome-start'),
                                        onPressed: widget.onWelcomeDone,
                                        child: const Text('はじめる'),
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  SizedBox(height: viewport.maxHeight * .12),
                                  const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: ForestWordmark(
                                      fontSize: 42,
                                      showSideDecorations: false,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const TaglineRibbon(),
                                  SizedBox(height: viewport.maxHeight * .40),
                                  PressFeedback(
                                    enabled: widget.ready && !leaping,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFFF5D8,
                                        ).withValues(alpha: .88),
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: const Color(0xFFFFD46C),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFFFDF75,
                                            ).withValues(alpha: .72),
                                            blurRadius: 22,
                                            spreadRadius: 2,
                                          ),
                                          const BoxShadow(
                                            color: Color(0x66452E13),
                                            offset: Offset(0, 4),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: FilledButton.icon(
                                        key: const ValueKey('title-start'),
                                        onPressed: widget.ready && !leaping
                                            ? start
                                            : null,
                                        icon: const Icon(Icons.auto_awesome),
                                        label: const Text('タップしてはじめる'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: const Color(
                                            0xFF51351B,
                                          ),
                                          shadowColor: Colors.transparent,
                                          minimumSize: const Size(230, 64),
                                          textStyle: const TextStyle(
                                            fontFamily: 'ZenMaru',
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!widget.ready)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Text(
                                        '森をひらいています…',
                                        style: TextStyle(fontSize: 17),
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
    ),
  );
}

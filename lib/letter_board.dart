import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game.dart';

const forestGreen = Color(0xFF35634C);

/// One horizontal row at every word length, including the six-letter puzzle.
class LetterBoard extends StatelessWidget {
  final String text;
  final int length;
  final List<Match>? marks;
  final bool active;
  final bool reveal;
  final bool compact;
  final bool dense;
  final VoidCallback? onRevealComplete;
  const LetterBoard({
    super.key,
    required this.text,
    required this.length,
    this.marks,
    this.active = false,
    this.reveal = false,
    this.compact = false,
    this.dense = false,
    this.onRevealComplete,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final gap = length > 4 ? 5.0 : 9.0;
      final width = math.min(
        dense
            ? active
                  ? 58.0
                  : 48.0
            : compact
            ? 64.0
            : active
            ? 100.0
            : 88.0,
        (box.maxWidth - gap * (length - 1)) / length,
      );
      final letters = text.characters.take(length).toList();
      final reduced = MediaQuery.disableAnimationsOf(context);
      // A slightly wider stagger makes the success wave readable without
      // keeping the player waiting; the full four-letter reveal stays under 1s.
      const revealStagger = 110;
      final total = 580 + (length - 1) * revealStagger;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: reveal ? 0 : 1, end: 1),
        duration: Duration(milliseconds: reduced ? 0 : total),
        onEnd: reveal ? onRevealComplete : null,
        builder: (context, value, child) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (i) {
            final elapsed = value * total - i * revealStagger;
            final phase = (elapsed / 320).clamp(0.0, 1.0);
            final settle = ((elapsed - 320) / 260).clamp(0.0, 1.0);
            final pulse = reveal && !reduced ? math.sin(settle * math.pi) : 0.0;
            final mark = phase < .5 ? null : marks?[i];
            final exact = mark == Match.exact;
            final glow =
                reveal && (marks?.every((mark) => mark == Match.exact) ?? false)
                ? pulse
                : 0.0;
            final color = exact
                ? Color.lerp(forestGreen, const Color(0xFF719B60), glow * .75)!
                : mark == Match.present
                ? const Color(0xFFF2D67C)
                : mark == Match.absent
                ? const Color(0xFFE2E4DF)
                : active
                ? const Color(0xFFFFFDF6)
                : Colors.white;
            final symbol = exact
                ? '◎'
                : mark == Match.present
                ? '△'
                : mark == Match.absent
                ? '×'
                : '';
            final character = i < letters.length ? letters[i] : '';
            final meaning = exact
                ? '文字も場所も正解'
                : mark == Match.present
                ? '場所が違う'
                : mark == Match.absent
                ? 'ない文字、または余った文字'
                : '入力中';
            return Padding(
              padding: EdgeInsets.only(right: i == length - 1 ? 0 : gap),
              child: Semantics(
                label:
                    '${i + 1}文字目、${character.isEmpty ? '空欄' : character}、$meaning',
                child: ExcludeSemantics(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('input-$i-$character'),
                    tween: Tween(
                      begin: active && character.isNotEmpty && !reduced
                          ? .86
                          : 1,
                      end: 1,
                    ),
                    duration: Duration(milliseconds: reduced ? 0 : 180),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Transform.translate(
                      offset: Offset(
                        reveal && !reduced && mark != null && !exact
                            ? math.sin(settle * math.pi * 2) * pulse * 3
                            : 0,
                        exact ? -pulse * (dense ? 5 : 9) : 0,
                      ),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(
                          1 + glow * .035,
                          reduced
                              ? 1
                              : math.cos(math.pi * phase).abs().clamp(.02, 1),
                          1,
                        ),
                        child: Container(
                          key: ValueKey('answer-cell-$i'),
                          width: width,
                          height: width * 1.08,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              width: active ? 2 : 1,
                              color: exact && glow > 0
                                  ? Color.lerp(
                                      const Color(0xFFB6C2B1),
                                      const Color(0xFFFFE29A),
                                      glow,
                                    )!
                                  : active
                                  ? forestGreen
                                  : const Color(0xFFB6C2B1),
                            ),
                            boxShadow: exact && glow > 0
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFFD978,
                                      ).withValues(alpha: glow * .72),
                                      blurRadius: 18 * glow,
                                      spreadRadius: 1.5 * glow,
                                    ),
                                  ]
                                : active
                                ? [
                                    const BoxShadow(
                                      color: Color(0x1035634C),
                                      offset: Offset(0, 3),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  child: Text(
                                    character.isEmpty ? ' ' : character,
                                    style: TextStyle(
                                      fontSize: width * .52,
                                      height: 1.1,
                                      fontWeight: FontWeight.w700,
                                      color: exact
                                          ? Colors.white
                                          : const Color(0xFF283D30),
                                    ),
                                  ),
                                ),
                              ),
                              if (mark != null)
                                Text(
                                  symbol,
                                  textScaler: TextScaler.noScaling,
                                  style: TextStyle(
                                    fontSize: math.min(20, width * .3),
                                    height: 1.2,
                                    fontWeight: FontWeight.bold,
                                    color: exact
                                        ? Colors.white
                                        : const Color(0xFF283D30),
                                  ),
                                ),
                              if (active &&
                                  character.isEmpty &&
                                  i == letters.length)
                                Icon(
                                  Icons.edit_outlined,
                                  size: math.min(24, width * .35),
                                  color: const Color(0xFF657F5D),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    },
  );
}

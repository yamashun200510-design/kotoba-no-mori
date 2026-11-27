import 'package:flutter/material.dart';

const kanaRows = [
  'あいうえお',
  'かきくけこ',
  'さしすせそ',
  'たちつてと',
  'なにぬねの',
  'はひふへほ',
  'まみむめも',
  'やゆよ',
  'らりるれろ',
  'わをんー',
];

enum KanaChange { voiced, halfVoiced, small }

/// Replaces the last kana; never inserts an extra character into the answer.
String changeKana(String kana, KanaChange change) {
  const plain = 'かきくけこさしすせそたちつてとはひふへほう';
  const voiced = 'がぎぐげござじずぜぞだぢづでどばびぶべぼゔ';
  const h = 'はひふへほ', b = 'ばびぶべぼ', p = 'ぱぴぷぺぽ';
  const big = 'あいうえおつやゆよわかけ', small = 'ぁぃぅぇぉっゃゅょゎゕゖ';
  if (change == KanaChange.small) {
    final index = big.indexOf(kana);
    if (index >= 0 && kana.isNotEmpty) return small[index];
    final reverse = small.indexOf(kana);
    return reverse >= 0 && kana.isNotEmpty ? big[reverse] : kana;
  }
  if (change == KanaChange.halfVoiced) {
    if (p.contains(kana) && kana.isNotEmpty) return h[p.indexOf(kana)];
    final index = h.indexOf(kana);
    if (index >= 0 && kana.isNotEmpty) return p[index];
    final other = b.indexOf(kana);
    return other >= 0 && kana.isNotEmpty ? p[other] : kana;
  }
  if (p.contains(kana) && kana.isNotEmpty) return b[p.indexOf(kana)];
  final index = plain.indexOf(kana);
  if (index >= 0 && kana.isNotEmpty) return voiced[index];
  final reverse = voiced.indexOf(kana);
  return reverse >= 0 && kana.isNotEmpty ? plain[reverse] : kana;
}

/// The same input callbacks serve the two-page and full-table presentations.
class KanaKeyboard extends StatefulWidget {
  final bool swipe, showSwipeGuide;
  final VoidCallback? onDisplaySettings;
  final String text;
  final bool full;
  final double maxTableHeight;
  final ValueChanged<String> onLetter;
  final ValueChanged<KanaChange> onChange;
  const KanaKeyboard({
    super.key,
    required this.text,
    required this.full,
    required this.onLetter,
    required this.onChange,
    this.maxTableHeight = 380,
    this.swipe = true,
    this.showSwipeGuide = false,
    this.onDisplaySettings,
  });

  static const table = [
    ['あ', 'い', 'う', 'え', 'お'],
    ['か', 'き', 'く', 'け', 'こ'],
    ['さ', 'し', 'す', 'せ', 'そ'],
    ['た', 'ち', 'つ', 'て', 'と'],
    ['な', 'に', 'ぬ', 'ね', 'の'],
    ['は', 'ひ', 'ふ', 'へ', 'ほ'],
    ['ま', 'み', 'む', 'め', 'も'],
    ['や', '', 'ゆ', '', 'よ'],
    ['ら', 'り', 'る', 'れ', 'ろ'],
    ['わ', 'を', 'ん', 'ー', ''],
  ];

  @override
  State<KanaKeyboard> createState() => _KanaKeyboardState();
}

class _KanaKeyboardState extends State<KanaKeyboard> {
  final pages = PageController(keepPage: false);
  int page = 0;
  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(KanaKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.swipe != widget.swipe) page = 0;
  }

  void select(int index) {
    if (!pages.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      pages.jumpToPage(index);
    } else {
      pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget table(int first, int end, double height) {
    final rowHeight = widget.swipe
        ? ((height - 4) / 5).clamp(48.0, 68.0)
        : 48.0;
    return Scrollbar(
      interactive: false,
      child: SingleChildScrollView(
        key: ValueKey(widget.swipe ? 'kana-page-$first' : 'kana-table'),
        primary: false,
        child: Column(
          children: [
            for (var row = first; row < end; row++) ...[
              if (row > first) const SizedBox(height: 1),
              SizedBox(
                height: rowHeight,
                child: Row(
                  children: [
                    for (var column = 0; column < 5; column++) ...[
                      if (column > 0) const SizedBox(width: 4),
                      Expanded(
                        child: KanaKeyboard.table[row][column].isEmpty
                            ? const SizedBox.shrink()
                            : SizedBox.expand(
                                child: _KanaKey(
                                  key: ValueKey(
                                    'kana-${KanaKeyboard.table[row][column]}',
                                  ),
                                  label: KanaKeyboard.table[row][column],
                                  letter: true,
                                  large: widget.swipe,
                                  tint: const [
                                    Color(0xFFE3EED3),
                                    Color(0xFFFFEDBF),
                                    Color(0xFFF7DCE3),
                                    Color(0xFFF8E0C6),
                                    Color(0xFFE0EBE8),
                                  ][row % 5],
                                  onPressed: widget.full
                                      ? null
                                      : () => widget.onLetter(
                                          KanaKeyboard.table[row][column],
                                        ),
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.text.isEmpty ? '' : widget.text.characters.last;
    final header = widget.swipe && widget.showSwipeGuide
        ? 70.0
        : widget.swipe
        ? 50.0
        : 50.0;
    final height = (widget.maxTableHeight - header).clamp(
      96.0,
      widget.swipe ? 344.0 : 489.0,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.swipe)
          SizedBox(
            height: 48,
            child: Row(
              children: [
                for (var index = 0; index < 2; index++) ...[
                  if (index > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Semantics(
                      selected: page == index,
                      child: TextButton(
                        key: ValueKey('kana-tab-$index'),
                        onPressed: () => select(index),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: page == index
                              ? const Color(0xFF35634C)
                              : const Color(0xFFE9EFDC),
                          foregroundColor: page == index
                              ? Colors.white
                              : const Color(0xFF294731),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text(index == 0 ? 'あ〜な' : 'は〜わ'),
                      ),
                    ),
                  ),
                ],
                if (widget.onDisplaySettings != null) ...[
                  const SizedBox(width: 6),
                  _keyboardSettingsButton(),
                ],
              ],
            ),
          ),
        if (!widget.swipe)
          SizedBox(
            height: 48,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '五十音すべて表示',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.onDisplaySettings != null) _keyboardSettingsButton(),
              ],
            ),
          ),
        if (widget.showSwipeGuide && widget.swipe)
          const SizedBox(
            height: 20,
            child: Text(
              '左右にスワイプできます',
              style: TextStyle(fontSize: 14, color: Color(0xFF4C6547)),
            ),
          ),
        const SizedBox(height: 2),
        SizedBox(
          height: height,
          child: widget.swipe
              ? PageView.builder(
                  key: const ValueKey('kana-pages'),
                  controller: pages,
                  itemCount: 2,
                  onPageChanged: (index) => setState(() => page = index),
                  itemBuilder: (context, index) =>
                      table(index * 5, index * 5 + 5, height),
                )
              : table(0, 10, height),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final change in KanaChange.values) ...[
              if (change != KanaChange.voiced) const SizedBox(width: 4),
              Expanded(
                child: Tooltip(
                  message: '最後の文字を変えます',
                  child: _KanaKey(
                    key: ValueKey('change-${change.name}'),
                    label:
                        (switch (change) {
                          KanaChange.voiced => '濁点 ゛',
                          KanaChange.halfVoiced => '半濁点 ゜',
                          KanaChange.small => '小文字',
                        }) +
                        (last.isNotEmpty && changeKana(last, change) != last
                            ? '\n$last→${changeKana(last, change)}'
                            : ''),
                    onPressed: last.isEmpty || changeKana(last, change) == last
                        ? null
                        : () => widget.onChange(change),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _keyboardSettingsButton() => OutlinedButton.icon(
    key: const ValueKey('keyboard-display-settings'),
    onPressed: widget.onDisplaySettings,
    icon: const Icon(Icons.settings_rounded, size: 17),
    label: const Text('文字盤設定', maxLines: 1),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      foregroundColor: const Color(0xFF4E402A),
      backgroundColor: const Color(0xFFFFF3D5),
      side: const BorderSide(color: Color(0xFFB99458)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );
}

class _KanaKey extends StatefulWidget {
  final String label;
  final bool letter;
  final bool large;
  final Color tint;
  final VoidCallback? onPressed;
  const _KanaKey({
    super.key,
    required this.label,
    this.letter = false,
    this.large = false,
    this.tint = const Color(0xFFEAF0DF),
    required this.onPressed,
  });
  @override
  State<_KanaKey> createState() => _KanaKeyState();
}

class _KanaKeyState extends State<_KanaKey> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) {
      if (widget.onPressed != null) setState(() => pressed = true);
    },
    onPointerUp: (_) => setState(() => pressed = false),
    onPointerCancel: (_) => setState(() => pressed = false),
    child: AnimatedScale(
      scale: pressed ? .94 : 1,
      duration: Duration(
        milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 90,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFB7A386),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF866B43).withValues(alpha: .14),
              offset: Offset(0, pressed ? 0 : 2),
              blurRadius: 1,
            ),
          ],
        ),
        child: Semantics(
          child: TextButton(
            onPressed: widget.onPressed,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              backgroundColor: widget.tint,
              disabledBackgroundColor: const Color(0xFFE8E6DE),
              foregroundColor: const Color(0xFF294731),
              disabledForegroundColor: const Color(0xFF65675F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: widget.onPressed == null
                      ? const Color(0xFFBCBDB5)
                      : widget.letter
                      ? const Color(0xFFB8AC8D)
                      : const Color(0xFF55714E),
                  width: !widget.letter && widget.onPressed != null ? 2 : 1,
                ),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: '',
                  fontSize: widget.letter ? (widget.large ? 32 : 26) : 18,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'letter_board.dart';
import 'game.dart';

/// A tiny hands-on example, separate from progress and rewards.
/// Split into short steps so it never needs scrolling on a normal phone.
class FirstSteps extends StatefulWidget {
  final VoidCallback onDone;
  const FirstSteps({super.key, required this.onDone});
  @override
  State<FirstSteps> createState() => _FirstStepsState();
}

class _FirstStepsState extends State<FirstSteps> {
  String text = '';
  int step = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: step == 0 ? handsOn() : legend(),
  );

  List<Widget> handsOn() => [
    const Text(
      'はじめの一歩　（1/2）',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 6),
    const Text('下の文字を「さ・く・ら」の順に押してみましょう。'),
    const SizedBox(height: 10),
    LetterBoard(
      text: text,
      length: 3,
      compact: true,
      marks: text == 'さくら' ? judge('さくら', text) : null,
    ),
    Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (final letter in ['さ', 'く', 'ら'])
          OutlinedButton(
            onPressed: text.length < 3
                ? () => setState(() => text += letter)
                : null,
            child: Text(letter),
          ),
        TextButton(
          onPressed: text.isEmpty
              ? null
              : () =>
                    setState(() => text = text.substring(0, text.length - 1)),
          child: const Text('1文字けす'),
        ),
      ],
    ),
    const SizedBox(height: 8),
    FilledButton(
      key: const ValueKey('first-steps-next'),
      onPressed: () => setState(() => step = 1),
      child: const Text('次へ'),
    ),
    TextButton(onPressed: widget.onDone, child: const Text('スキップ')),
  ];

  List<Widget> legend() => [
    const Text(
      '記号の見かた　（2/2）',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 12),
    const Text(
      '緑 ◎：文字も場所も正しい\n\n'
      '黄色 △：文字はあるけれど場所が違う\n\n'
      '灰色 ×：ない文字・余った文字',
      style: TextStyle(fontSize: 18, height: 1.6),
    ),
    const SizedBox(height: 16),
    FilledButton(onPressed: widget.onDone, child: const Text('あそびはじめる')),
    TextButton(
      onPressed: () => setState(() => step = 0),
      child: const Text('もどる'),
    ),
  ];
}

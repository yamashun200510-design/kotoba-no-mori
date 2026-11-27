import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'invitation.dart';
import 'rabbit_mascot.dart';

class InvitationPanel extends StatefulWidget {
  final ValueChanged<InvitationPuzzle> onPlay;
  const InvitationPanel({super.key, required this.onPlay});
  @override
  State<InvitationPanel> createState() => _InvitationPanelState();
}

class _InvitationPanelState extends State<InvitationPanel> {
  final answer = TextEditingController(),
      code = TextEditingController(),
      hint = TextEditingController();
  bool creating = true;
  int length = 3;
  String generated = '', message = '';
  @override
  void dispose() {
    answer.dispose();
    code.dispose();
    hint.dispose();
    super.dispose();
  }

  void create() {
    final word = InvitationCode.canonical(answer.text);
    final error =
        InvitationCode.validate(word) ?? InvitationCode.validateHint(hint.text);
    setState(() {
      generated = '';
      message =
          error ?? (word.runes.length != length ? '$length文字のことばを入れてね。' : '');
      if (message.isEmpty) {
        generated = InvitationCode.create(word, hint: hint.text.trim());
        FocusScope.of(context).unfocus();
      }
    });
  }

  void play() {
    try {
      final puzzle = InvitationCode.restore(code.text);
      FocusScope.of(context).unfocus();
      widget.onPlay(puzzle);
    } on FormatException catch (error) {
      setState(() => message = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Row(
        children: [
          RabbitMascot(width: 76, height: 106, mood: RabbitMood.present),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'ことばを包んで、\n友だちへ。',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF35634C),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: true, label: Text('問題をつくる')),
          ButtonSegment(value: false, label: Text('コードであそぶ')),
        ],
        selected: {creating},
        showSelectedIcon: false,
        style: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(48, 56)),
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        onSelectionChanged: (value) => setState(() {
          creating = value.first;
          message = '';
        }),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1CE),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD4BC8E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (creating) ...[
              const Text(
                '正解のことば',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const Text('名前や、作ったことばも使えます。', style: TextStyle(fontSize: 17)),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 3, label: Text('3文字')),
                  ButtonSegment(value: 4, label: Text('4文字')),
                ],
                selected: {length},
                onSelectionChanged: (value) => setState(() {
                  length = value.first;
                  generated = '';
                  message = '';
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('invitation-answer'),
                controller: answer,
                style: const TextStyle(fontSize: 26),
                decoration: const InputDecoration(
                  labelText: 'ひらがなで入力',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {
                  generated = '';
                  message = '';
                }),
                onSubmitted: (_) => create(),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('invitation-hint'),
                controller: hint,
                maxLength: 40,
                minLines: 1,
                maxLines: 3,
                style: const TextStyle(fontSize: 19),
                decoration: const InputDecoration(
                  labelText: 'ヒント（なくても大丈夫）',
                  helperText: '40文字まで。解く人が押したときだけ表示します。',
                  helperMaxLines: 2,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {
                  generated = '';
                  message = '';
                }),
              ),
              if (InvitationCode.hintContainsAnswer(answer.text, hint.text))
                const Text(
                  'ヒントに正解が入っています。送る前に確認してね。',
                  key: ValueKey('hint-answer-warning'),
                  style: TextStyle(fontSize: 17, color: Color(0xFF8B4E24)),
                ),
              const SizedBox(height: 14),
              FilledButton(
                key: const ValueKey('create-invitation'),
                onPressed: create,
                child: const Text('招待コードをつくる'),
              ),
              if (generated.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text('招待コード', textAlign: TextAlign.center),
                SelectableText(
                  generated,
                  key: const ValueKey('invitation-code'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: generated.startsWith('K2.') ? 18 : 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: generated.startsWith('K2.') ? 0 : 2,
                    color: Color(0xFF35634C),
                  ),
                ),
                const SizedBox(height: 8),
                if (generated.startsWith('K2.'))
                  const Text(
                    'ヒント付きのコードは長くなります。コピーして送り、届いた人は貼り付けてね。',
                    style: TextStyle(fontSize: 17),
                  ),
                OutlinedButton.icon(
                  key: const ValueKey('copy-invitation'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: generated));
                    if (mounted) {
                      setState(() => message = 'コピーしました。LINEやSNSに貼り付けて送ってね。');
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('コードをコピー'),
                ),
              ],
            ] else ...[
              const Text(
                '届いたコードを入れてね',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('invitation-code-input'),
                controller: code,
                textCapitalization: TextCapitalization.none,
                minLines: 1,
                maxLines: 3,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontSize: 24),
                decoration: const InputDecoration(
                  labelText: '招待コード',
                  hintText: 'XXXXX-XXXXX',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => play(),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                key: const ValueKey('paste-invitation'),
                onPressed: () async {
                  final value = await Clipboard.getData(Clipboard.kTextPlain);
                  if (mounted && value?.text != null) {
                    setState(() {
                      code.text = value!.text!;
                      message = '';
                    });
                  }
                },
                icon: const Icon(Icons.paste),
                label: const Text('コードを貼り付け'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey('play-invitation'),
                onPressed: play,
                child: const Text('この招待状であそぶ'),
              ),
            ],
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    key: const ValueKey('invitation-message'),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF67471E),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'コードを知っている人だけが遊べます。\n招待問題はコイン・今日の目標の対象外です。',
        style: TextStyle(fontSize: 17, height: 1.5),
      ),
    ],
  );
}

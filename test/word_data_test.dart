import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/kana_keyboard.dart';
import 'package:kotoba_no_mori/word_validation.dart';

void main() {
  test('全データが実際の五十音キーボードで入力でき、形式検査を通る', () {
    final reachable = kanaRows.join().split('').toSet();
    for (final c in reachable.toList()) {
      for (final change in KanaChange.values) {
        reachable.add(changeKana(c, change));
      }
    }
    expect(validateWords(words, inputCharacters: reachable), isEmpty);
    expect(
      additionalWords.every(
        (w) => w.declaredLength != null && w.category != null,
      ),
      true,
    );
    expect(
      words.where((w) => w.text.length == 3).length,
      greaterThanOrEqualTo(100),
    );
    expect(
      words.where((w) => w.text.length == 4).length,
      greaterThanOrEqualTo(100),
    );
    expect(
      words.where((w) => w.text.length == 5).length,
      greaterThanOrEqualTo(50),
    );
    expect(() => Progress().selectMode(5), throwsArgumentError);
  });

  test('検査が重複・長さ・不正文字・入力不能文字・カテゴリ・ヒントを検出する', () {
    final errors = validateWords(
      [
        const Word.entry('さくら', 3, 'しょくぶつ', '春の花です。'),
        const Word.entry('さくら', 4, 'しょくぶつ', '春の花です。'),
        const Word.entry('カタカナ', 4, 'しょくぶつ', '説明'),
        const Word.entry('', 3, '', ''),
        const Word.entry('さくら ', 3, '未知', ' 説明\n'),
      ],
      inputCharacters: {'さ', 'く'},
    );
    for (final fragment in [
      '重複',
      '不一致',
      '不正文字',
      '入力不可能',
      'カテゴリ欠落',
      'ヒント欠落',
      '形式不正',
      '未知のカテゴリ',
    ]) {
      expect(errors.any((e) => e.contains(fragment)), true, reason: fragment);
    }
  });

  for (final length in [3, 4]) {
    for (final round in [0, 2]) {
      test('旧$length文字の${round + 1}周目の途中問題を維持し、新規問題を優先・永続化する', () {
        final old = legacyWords
            .where((w) => w.text.length == length)
            .map((w) => w.text)
            .toList();
        final index = 4;
        final saved = ModePuzzle(
          length,
          order: old,
          cursor: old.length * round + index,
          guesses: ['あ' * length],
          draft: 'さ',
          hints: 1,
        ).encode();
        final restored = ModePuzzle.decode(length, saved);
        expect(restored.word.text, old[index]);
        expect(restored.guesses, ['あ' * length]);
        expect(restored.draft, 'さ');
        expect(restored.hints, 1);
        final added = words
            .where((w) => w.text.length == length && !old.contains(w.text))
            .map((w) => w.text)
            .toList();
        expect(restored.order.skip(1).take(added.length), added);
        expect(
          restored.order.toSet().length,
          words.where((w) => w.text.length == length).length,
        );
        final again = ModePuzzle.decode(length, restored.encode());
        expect(again.encode(), restored.encode());
        final p = Progress(
          mode: length,
          modes: {length: again},
          coins: 75,
          ownedItems: {'tulip'},
        );
        p.submit(p.word.text);
        p.next();
        expect(p.word.text, added.first);
        final reloaded = Progress.decode(p.encode());
        expect(reloaded.word.text, added.first);
        expect(reloaded.coins, 85);
        expect(reloaded.ownedItems, {'tulip'});
      });
    }
  }

  test('旧問題の周回と公開済みの今日のことばの日付対応はデータ増加後も変わらない', () {
    final p = Progress(solved: legacyWords.length * 3 + 7, guesses: ['あいう']);
    final restored = Progress.decode(p.encode());
    expect(restored.word.text, 'もみじ');
    expect(restored.guesses, ['あいう']);
    for (var i = 0; i < 100; i++) {
      final day = DateTime.utc(2026, 10, 23).add(Duration(days: i));
      final oldWord =
          legacyWords[(day.millisecondsSinceEpoch ~/
                  Duration.millisecondsPerDay) %
              legacyWords.length];
      expect(TodayPuzzle.forDate(Progress.dayKey(day)).text, oldWord.text);
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/game.dart';

void main() {
  for (final length in [3, 4]) {
    test('$length文字は一巡まで重複せず、再起動と2周目でも順序・報酬を保つ', () {
      var p = Progress(mode: length);
      final count = words.where((w) => w.text.length == length).length;
      final rounds = <List<String>>[];
      for (var round = 0; round < 2; round++) {
        final order = <String>[];
        for (var i = 0; i < count; i++) {
          expect(p.word.text.length, length);
          order.add(p.word.text);
          expect(p.submit('あ' * (length - 1)), false);
          expect(p.submit('あ' * length, now: DateTime(2026, 10, 23)), true);
          expect(p.won, false);
          expect(p.submit(p.word.text, now: DateTime(2026, 10, 23)), true);
          p = Progress.decode(p.encode());
          expect(p.won, true);
          p.next();
          p = Progress.decode(p.encode());
        }
        expect(order.toSet().length, count);
        expect(p.coins, count * 10 + 30);
        rounds.add(order);
      }
      expect(rounds[0], rounds[1]);
      expect(p.modes[length]!.cursor, count * 2);
    });
  }

  test('モード変更・再読込でも回答・入力中・ヒント・森の成長を保持する', () {
    var p = Progress(mode: 3, coins: 70, ownedItems: {'tulip'});
    p.submit('あいう');
    p.hints = 2;
    p.draft = 'さく';
    p.selectMode(4);
    p.submit('あいうえ');
    p.hints = 1;
    p.draft = 'たん';
    p = Progress.decode(p.encode());
    expect(p.mode, 4);
    expect(p.guesses, ['あいうえ']);
    expect(p.draft, 'たん');
    p.selectMode(3);
    expect(p.guesses, ['あいう']);
    expect(p.hints, 2);
    expect(p.draft, 'さく');
    p.submit(p.word.text);
    final growth = p.totalSolved;
    p.selectMode(4);
    expect(p.totalSolved, growth);
    expect(p.coins, 80);
    expect(p.ownedItems, {'tulip'});
  });

  test('旧3文字の途中問題を同じ答えで移し、未出題を優先する', () {
    var p = Progress.decode(
      Progress(solved: 4, guesses: ['あいう'], hints: 1, coins: 40).encode(),
    );
    p.selectMode(3);
    expect(p.word.text, 'すみれ');
    expect(p.guesses, ['あいう']);
    expect(p.hints, 1);
    expect(p.legacyAvailable, false);
    expect(p.modes[3]!.order.take(2), ['すみれ', 'きつね']);
    p = Progress.decode(p.encode());
    expect(p.word.text, 'すみれ');
    expect(p.coins, 40);
  });

  test('旧6文字の回答を残したまま別モードを解いても旧問題がずれない', () {
    var p = Progress(solved: 23, guesses: ['あいうえおか'], hints: 2);
    p.selectMode(4);
    p.submit(p.word.text);
    p.next();
    p = Progress.decode(p.encode());
    p.resumeLegacy();
    expect(p.word.text, 'しろつめくさ');
    expect(p.guesses, ['あいうえおか']);
    expect(p.hints, 2);
  });

  test('問題が一語だけでも次へ進め、空のモードや不正な単語を拒否する', () {
    final p = Progress(
      mode: 3,
      modes: {
        3: ModePuzzle(3, order: ['さくら']),
      },
    );
    p.submit('さくら');
    p.next();
    expect(p.word.text, 'さくら');
    expect(p.guesses, isEmpty);
    expect(
      () => ModePuzzle.decode(3, {
        'order': [],
        'cursor': 0,
        'guesses': [],
        'hints': 0,
      }),
      throwsFormatException,
    );
    expect(
      () => ModePuzzle.decode(4, {
        'order': ['さくら'],
        'cursor': 0,
        'guesses': [],
        'hints': 0,
      }),
      throwsFormatException,
    );
    expect(
      () => ModePuzzle.decode(3, {
        'order': ['さくら', 'さくら'],
        'cursor': 0,
        'guesses': [],
        'hints': 0,
      }),
      throwsFormatException,
    );
  });
}

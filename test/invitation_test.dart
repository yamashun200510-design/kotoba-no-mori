import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/invitation.dart';
import 'package:kotoba_no_mori/game.dart';

void main() {
  test('任意ヒント・40文字・絵文字を復元し、旧コードも維持する', () {
    for (final hint in [
      '',
      'あたたかい飲みものです。',
      'あ' * 40,
      'a' * 40,
      '🌷' * 40,
      '家族👨‍👩‍👧‍👦で楽しむ',
    ]) {
      final code = InvitationCode.create('ここあ', hint: hint);
      final restored = InvitationCode.restore(code);
      expect(restored.answer, 'ここあ');
      expect(restored.hint, hint);
      expect(restored.hints, 0);
      expect(restored.guesses, isEmpty);
      if (hint.isEmpty) expect(code.length, 11);
    }
    expect(InvitationCode.create('ここあ', hint: 'あ' * 40).length, 186);
    expect(InvitationCode.create('ここあ', hint: 'a' * 40).length, 79);
    expect(
      () => InvitationCode.create('ここあ', hint: 'あ' * 41),
      throwsFormatException,
    );
    expect(InvitationCode.hintContainsAnswer('ここあ', 'あたたかいココア'), true);
  });

  test('ヒントの不適切表現・破損・長すぎるコードを拒否する', () {
    expect(InvitationCode.validateHint('花のかたわらにあります'), isNull);
    expect(InvitationCode.validateHint('こころすること'), isNull);
    expect(
      InvitationCode.validateHint('レイプを表すことば'),
      InvitationCode.blockedHint,
    );
    expect(
      () => InvitationCode.create('ここあ', hint: 'レイプを表すことば'),
      throwsFormatException,
    );
    final code = InvitationCode.create('ここあ', hint: '🌷や花のある森');
    final parts = code.split('.');
    final damaged =
        '${parts[0]}.${parts[1]}.${parts[2] == '00000000' ? '11111111' : '00000000'}';
    expect(() => InvitationCode.restore(damaged), throwsFormatException);
    expect(
      () => InvitationCode.restore('K2.not-a-code.abcd'),
      throwsFormatException,
    );
    expect(() => InvitationCode.restore('X' * 4097), throwsFormatException);
  });
  test('自由な3・4文字、濁点・半濁点・小文字・長音を別セッションで復元する', () {
    for (final word in ['さくら', 'ぽぴゃ', 'ぷくりん', 'ゔぁる', 'こーひー', 'ゖゕゎ', 'ここあ']) {
      for (var i = 0; i < 40; i++) {
        final code = InvitationCode.create(word);
        expect(code.length, 11);
        expect(InvitationCode.decode(code), word);
        expect(
          InvitationCode.decode(' ${code.toLowerCase().replaceAll('-', ' ')} '),
          word,
        );
        expect(InvitationPuzzle(InvitationCode.decode(code)).answer, word);
      }
    }
    expect(
      InvitationCode.decode(InvitationCode.create('は\u309aひ\u3099ゃ')),
      'ぱびゃ',
    );
  });

  test('文字数・文字種・完全一致の禁止語を検査する', () {
    for (final word in [
      '',
      'あい',
      'あいうえお',
      'サクラ',
      'あ1う',
      'あ う',
      '😀あい',
      'ーーー',
      'あ゙いう',
    ]) {
      expect(InvitationCode.validate(word), isNotNull);
      expect(() => InvitationCode.create(word), throwsFormatException);
    }
    expect(InvitationCode.validate('ころす'), InvitationCode.blocked);
    expect(InvitationCode.validate('しねま'), isNull);
    expect(InvitationCode.validate('ころも'), isNull);
  });

  test('空・不正な形式・全位置の一文字入力ミスを拒否する', () {
    for (final input in [
      '',
      '123',
      'XXXXXXXXXXX',
      'あいうえおかきくけこ',
      '!!!!!!!!!!',
    ]) {
      expect(() => InvitationCode.decode(input), throwsFormatException);
    }
    final code = InvitationCode.create('たんぽぽ').replaceAll('-', '');
    for (var i = 0; i < code.length; i++) {
      for (final letter in InvitationCode.alphabet.split('')) {
        if (letter == code[i]) continue;
        final changed = code.substring(0, i) + letter + code.substring(i + 1);
        expect(() => InvitationCode.decode(changed), throwsFormatException);
      }
    }
  });

  test('招待問題は判定を再利用し、通常進行と報酬に触れず再試行できる', () {
    final progress = Progress(coins: 123, mode: 4);
    final before = progress.encode();
    final guest = InvitationPuzzle('ここあ');
    expect(guest.submit('ここ'), false);
    expect(guest.submit('あああ'), true);
    expect(judge(guest.answer, guest.guesses.single), [
      Match.absent,
      Match.absent,
      Match.exact,
    ]);
    expect(guest.submit('ここあ'), true);
    expect(guest.won, true);
    expect(guest.submit('ここあ'), false);
    expect(progress.encode(), before);
  });
}

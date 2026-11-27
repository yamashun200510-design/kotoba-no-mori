import 'game.dart';

/// Structural checks only: Japanese meaning and familiarity need human review.
List<String> validateWords(
  Iterable<Word> entries, {
  Set<String>? inputCharacters,
}) {
  final errors = <String>[];
  final seen = <String>{};
  final reachable =
      inputCharacters ??
      'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをんー'
              'がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽゔぁぃぅぇぉっゃゅょゎゕゖ'
          .split('')
          .toSet();
  const categories = {
    'どうぶつ',
    'たべもの',
    'のみもの',
    'しょくぶつ',
    'くらし',
    'のりもの',
    'あそび',
    'しぜん',
    'ばしょ',
    'ひと',
  };
  for (final entry in entries) {
    final text = entry.text;
    void error(String message) => errors.add('$text: $message');
    if (!seen.add(text)) error('重複単語');
    if (text.isEmpty ||
        text.trim() != text ||
        !RegExp(r'^[ぁ-ゖー]+$').hasMatch(text)) {
      error('空欄・不正文字・余分な空白');
    }
    if (entry.declaredLength != null &&
        entry.declaredLength != text.runes.length) {
      error('宣言した文字数と不一致');
    }
    if (entry.declaredLength != null &&
        ![3, 4, 5].contains(entry.declaredLength)) {
      error('追加データの対象外の文字数');
    }
    if (entry.category != null && entry.category!.trim().isEmpty) {
      error('カテゴリ欠落');
    }
    if (!categories.contains(entry.genre)) error('未知のカテゴリ');
    if (entry.clue.trim().isEmpty) error('ヒント欠落');
    if (entry.clue.trim() != entry.clue || entry.clue.contains('\n')) {
      error('ヒントの形式不正');
    }
    if (text.split('').any((c) => !reachable.contains(c))) error('入力不可能な文字');
  }
  return errors;
}

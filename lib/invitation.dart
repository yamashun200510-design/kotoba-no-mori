import 'dart:math';
import 'dart:convert';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'game.dart';
import 'invitation_words.dart';

class InvitationCode {
  static const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static const invalid = 'コードを確認して、もう一度入力してね。';
  static const blocked = 'このことばは問題にできません。別のことばを選んでね';
  static const blockedHint = 'このヒントは使えません。別のヒントにしてね。';

  static String _reading(String text) => canonical(
    String.fromCharCodes(
      text.runes.map((r) => r >= 0x30a1 && r <= 0x30f6 ? r - 0x60 : r),
    ),
  );

  static String? validateHint(String hint) {
    if (hint.characters.length > 40) return 'ヒントは40文字以内にしてね。';
    if (utf8.encode(hint).length > 2048 ||
        RegExp(r'[\x00-\x08\x0b-\x1f\x7f]').hasMatch(hint)) {
      return 'ヒントの文字を確認してね。';
    }
    final reading = _reading(hint);
    if (invitationBlockedWords.contains(reading) ||
        invitationBlockedHintFragments.any(reading.contains)) {
      return blockedHint;
    }
    return null;
  }

  static bool hintContainsAnswer(String answer, String hint) =>
      answer.isNotEmpty && _reading(hint).contains(_reading(answer));

  static int _crc(List<int> bytes) {
    var crc = 0xffffffff;
    for (final byte in bytes) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xedb88320 : 0);
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }

  static String canonical(String text) {
    const plain = 'かきくけこさしすせそたちつてとはひふへほう';
    const voiced = 'がぎぐげござじずぜぞだぢづでどばびぶべぼゔ';
    const h = 'はひふへほ', p = 'ぱぴぷぺぽ';
    var value = text.trim();
    for (var i = 0; i < plain.length; i++) {
      value = value.replaceAll('${plain[i]}\u3099', voiced[i]);
    }
    for (var i = 0; i < h.length; i++) {
      value = value.replaceAll('${h[i]}\u309a', p[i]);
    }
    return value;
  }

  static String? validate(String text) {
    final word = canonical(text);
    if (![3, 4].contains(word.runes.length) ||
        !RegExp(r'^[ぁ-ゖー]+$').hasMatch(word) ||
        !RegExp(r'[ぁ-ゖ]').hasMatch(word)) {
      return 'ひらがなで、3文字か4文字のことばを入れてね。';
    }
    return invitationBlockedWords.contains(word) ? blocked : null;
  }

  static int _mask(int nonce) {
    var x = (nonce + 1) * 0x45d9f3b;
    x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0x7fffffff;
    return (x ^ (x >> 16) ^ 0x69a53cb) & 0xfffffff;
  }

  static int _checksum(int payload) {
    var crc = 0;
    for (var i = 4; i >= 0; i--) {
      final byte = (payload >> (i * 8)) & 255;
      for (var bit = 7; bit >= 0; bit--) {
        final top = (crc >> 9) ^ ((byte >> bit) & 1);
        crc = (crc << 1) & 1023;
        if (top != 0) crc ^= 0x233;
      }
    }
    return crc;
  }

  /// Version 1: 40-bit payload + CRC-10, encoded as ten Crockford base32 symbols.
  /// XOR obscures plain kana; this is intentionally not encryption or access control.
  static String create(String text, {String hint = ''}) {
    final hintError = validateHint(hint);
    if (hintError != null) throw FormatException(hintError);
    if (hint.isNotEmpty) {
      final answerCode = create(text).replaceAll('-', '');
      final bytes = [...ascii.encode(answerCode), ...utf8.encode(hint)];
      return 'K2.${base64Url.encode(bytes).replaceAll('=', '')}.${_crc(bytes).toRadixString(16).padLeft(8, '0')}';
    }
    final error = validate(text);
    if (error != null) throw FormatException(error);
    final letters = canonical(text).runes.toList();
    final nonce = Random.secure().nextInt(256);
    var packed = 0;
    for (var i = 0; i < letters.length; i++) {
      packed |= (letters[i] == 0x30fc ? 86 : letters[i] - 0x3041) << (i * 7);
    }
    final payload =
        1 |
        ((letters.length - 3) << 3) |
        (nonce << 4) |
        ((packed ^ _mask(nonce)) << 12);
    var bits = (payload << 10) | _checksum(payload);
    var result = '';
    for (var i = 0; i < 10; i++) {
      result = alphabet[bits & 31] + result;
      bits >>= 5;
    }
    return '${result.substring(0, 5)}-${result.substring(5)}';
  }

  static InvitationPuzzle restore(String code) {
    if (code.length > 4096) throw const FormatException(invalid);
    final compact = code.replaceAll(RegExp(r'\s'), '');
    if (!compact.toUpperCase().startsWith('K2.')) {
      return InvitationPuzzle(_decodeLegacy(code));
    }
    try {
      final parts = compact.split('.');
      if (parts.length != 3 ||
          !RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(parts[2])) {
        throw const FormatException(invalid);
      }
      final bytes = base64Url.decode(base64Url.normalize(parts[1]));
      if (bytes.length <= 10 ||
          bytes.length > 2058 ||
          _crc(bytes) != int.parse(parts[2], radix: 16)) {
        throw const FormatException(invalid);
      }
      final answer = _decodeLegacy(ascii.decode(bytes.sublist(0, 10)));
      final hint = utf8.decode(bytes.sublist(10));
      final error = validateHint(hint);
      if (error != null) throw FormatException(error);
      return InvitationPuzzle(answer, hint: hint);
    } on FormatException catch (error) {
      if (error.message == blocked || error.message == blockedHint) rethrow;
      throw const FormatException(invalid);
    }
  }

  static String decode(String code) => restore(code).answer;

  static String _decodeLegacy(String code) {
    final cleaned = code
        .toUpperCase()
        .replaceAll(RegExp(r'[\s-]'), '')
        .replaceAll('O', '0')
        .replaceAll(RegExp('[IL]'), '1');
    if (cleaned.length != 10) throw const FormatException(invalid);
    var bits = 0;
    for (final char in cleaned.split('')) {
      final value = alphabet.indexOf(char);
      if (value < 0) throw const FormatException(invalid);
      bits = (bits << 5) | value;
    }
    final payload = bits >> 10;
    if ((bits & 1023) != _checksum(payload) || (payload & 7) != 1) {
      throw const FormatException(invalid);
    }
    final length = 3 + ((payload >> 3) & 1);
    final nonce = (payload >> 4) & 255;
    final packed = (payload >> 12) ^ _mask(nonce);
    final letters = <int>[];
    for (var i = 0; i < 4; i++) {
      final value = (packed >> (i * 7)) & 127;
      if (i >= length) {
        if (value != 0) throw const FormatException(invalid);
      } else {
        if (value > 86) throw const FormatException(invalid);
        letters.add(value == 86 ? 0x30fc : value + 0x3041);
      }
    }
    final word = String.fromCharCodes(letters);
    final error = validate(word);
    if (error != null) {
      throw FormatException(error == blocked ? blocked : invalid);
    }
    return word;
  }
}

/// Ephemeral guest play. No Progress instance, coins, records or reward writes.
class InvitationPuzzle {
  final String answer;
  final String hint;
  final List<String> guesses = [];
  int hints = 0;
  String draft = '';
  InvitationPuzzle(this.answer, {this.hint = ''});
  bool get won => guesses.contains(answer);
  Word get word => Word.entry(
    answer,
    answer.runes.length,
    'ユーザーが作成した問題です',
    hint.isEmpty ? 'この問題にはヒントがありません。' : hint,
  );
  bool submit(String text) {
    final guess = normalize(text);
    if (won ||
        guess.runes.length != answer.runes.length ||
        !RegExp(r'^[ぁ-ゖー]+$').hasMatch(guess)) {
      return false;
    }
    guesses.add(guess);
    return true;
  }
}

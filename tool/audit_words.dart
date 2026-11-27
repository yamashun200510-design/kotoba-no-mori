import 'dart:convert';
import 'dart:io';
import 'package:kotoba_no_mori/game.dart';
import 'package:kotoba_no_mori/word_validation.dart';

void main() {
  final unique = words.map((w) => w.text).toSet();
  final invalid = validateWords(words);
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'total': words.length,
      'three': words.where((w) => w.text.length == 3).length,
      'four': words.where((w) => w.text.length == 4).length,
      'fiveReserved': words.where((w) => w.text.length == 5).length,
      'other': words.where((w) => ![3, 4, 5].contains(w.text.length)).length,
      'byLength': {
        for (final length in words.map((w) => w.text.length).toSet())
          '$length': words.where((w) => w.text.length == length).length,
      },
      'duplicateExtraEntries': words.length - unique.length,
      'invalid': invalid,
      'normalPlayableUnique': unique
          .where((text) => [3, 4].contains(text.length))
          .length,
      'dailyPoolUnique': legacyWords.map((w) => w.text).toSet().length,
      'availableAcrossPublishedModes': {
        ...legacyWords.map((w) => w.text),
        ...unique.where((text) => [3, 4].contains(text.length)),
      }.length,
    }),
  );
  if (invalid.isNotEmpty) exitCode = 1;
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/game.dart';

Progress p({List<String>? guesses, String draft = '', int solved = 0, int coins = 0, bool large = false}) =>
    Progress(solved: solved, guesses: guesses, draft: draft, coins: coins, largeText: large,
        reduceMotion: true, soundEnabled: false, musicEnabled: false, welcomeSeen: true)
      ..loginDate = Progress.dayKey(DateTime.now())
      ..loginDay = 1;

void main() {
  test('seeds', () {
    final scenes = {
      'puzzle': p(guesses: ['さかな', 'くらげ'], draft: 'さく', large: true),
      'win': p(guesses: ['さかな', 'くらげ', 'さくら'], large: true),
      'home': p(solved: 8, coins: 120),
      'map': p(solved: 3),
      'modes': p(solved: 3),
    };
    Directory('build/seeds').createSync(recursive: true);
    scenes.forEach((k, v) => File('build/seeds/$k.json')
        .writeAsStringSync(jsonEncode({'flutter.forest_progress': v.encode()})));
  });
}

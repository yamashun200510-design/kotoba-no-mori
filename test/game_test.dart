import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/game.dart';

void main() {
  test('今日のことばは日付で決まり、通常問題を変えず保存・翌日更新できる', () {
    final day = DateTime(2026, 10, 23);
    var p = Progress(guesses: ['あいう'], hints: 1, soundEnabled: false);
    p.refreshDay(day);
    final answer = p.today.word.text;
    expect(TodayPuzzle.forDate('2026-10-23').text, answer);
    p.today.hints = 2;
    expect(p.submitToday(answer, now: day), true);
    expect(p.coins, 30);
    expect(p.totalSolved, 1);
    p = Progress.decode(p.encode());
    expect(p.today.won, true);
    expect(p.today.hints, 2);
    expect(p.soundEnabled, false);
    expect(p.submitToday(answer, now: day), false);
    expect(p.coins, 30);
    p.refreshDay(day.add(const Duration(days: 1)));
    expect(p.today.won, false);
    expect(p.today.guesses, isEmpty);
    expect(p.today.hints, 0);
    expect(p.today.word.text, isNot(answer));
    expect(p.guesses, ['あいう']);
    expect(p.hints, 1);
    expect(p.solved, 0);
    p.refreshDay(day);
    p.submitToday(answer, now: day);
    expect(p.coins, 30); // Clock rollback cannot reward the same date twice.
  });

  test('日次30コインは翌日再取得でき、未取得の過去日へ戻しても増えない', () {
    final day = DateTime(2026, 10, 23);
    var p = Progress();
    p.refreshDay(day);
    final wrong = 'あ' * p.today.word.text.length;
    expect(p.submitToday(wrong, now: day), true);
    expect(p.coins, 0);
    expect(p.submitToday(p.today.word.text, now: day), true);
    expect(p.coins, 30);
    expect(p.todayRewards, {'2026-10-23'});
    p = Progress.decode(p.encode());
    expect(p.submitToday(p.today.word.text, now: day), false);
    expect(p.coins, 30);
    final tomorrow = day.add(const Duration(days: 1));
    p.refreshDay(tomorrow);
    expect(p.today.won, false);
    expect(p.submitToday(p.today.word.text, now: tomorrow), true);
    expect(p.coins, 60);
    p.refreshDay(day.subtract(const Duration(days: 1)));
    p.submitToday(
      p.today.word.text,
      now: day.subtract(const Duration(days: 1)),
    );
    expect(p.coins, 60);
    expect(p.todayRewards, {'2026-10-23', '2026-10-24'});
    expect(p.purchase('tulip'), true);
    expect(Progress.decode(p.encode()).coins, 30);
  });

  test('旧保存のクリア日は受取済みとして移行し、ログイン・通常報酬と独立する', () {
    final day = DateTime(2026, 10, 23);
    final legacy = Progress(
      coins: 10,
      todayClears: {'2026-10-23'},
    ).encode().replaceFirst('"todayRewards":["2026-10-23"],', '');
    var p = Progress.decode(legacy);
    expect(p.todayRewards, {'2026-10-23'});
    p.submitToday(TodayPuzzle.forDate('2026-10-23').text, now: day);
    expect(p.coins, 10);
    p = Progress();
    expect(p.claimLogin(day), 10);
    expect(p.submit('さくら', now: day), true);
    p.submitToday(p.today.word.text, now: day);
    expect(p.coins, 50);
    p = Progress.decode(p.encode());
    expect(p.claimLogin(day), 0);
    expect(p.submitToday(p.today.word.text, now: day), false);
    expect(p.coins, 50);
  });

  test('ログインは1日一度、休んだ日も進行を保ち7日で循環し、再読込で再加算しない', () {
    var p = Progress(coins: 0);
    final gaps = [0, 2, 5, 6, 8, 12, 14, 18];
    for (var i = 0; i < gaps.length; i++) {
      final day = DateTime(2026, 10, 23 + gaps[i]);
      final reward = loginRewards[i % 7];
      final balance = p.coins;
      expect(p.claimLogin(day), reward);
      expect(p.loginDay, i % 7 + 1);
      expect(p.coins, balance + reward);
      p = Progress.decode(p.encode());
      expect(p.claimLogin(day), 0);
      expect(p.claimLogin(day.subtract(const Duration(days: 1))), 0);
      expect(p.coins, balance + reward);
    }
    expect(p.coins, 250);
    expect(p.loginDay, 1);
  });
  test('旧データは成長と所持金を保ち、観測済み日付以前ではログイン報酬を再発行しない', () {
    final p = Progress.decode(
      '{"version":1,"solved":4,"guesses":[],"hints":0,"largeText":false,"coins":80,"dailyDate":"2026-10-25"}',
    );
    expect(p.coins, 80);
    expect(p.solved, 4);
    expect(p.claimLogin(DateTime(2026, 10, 24)), 0);
    expect(p.claimLogin(DateTime(2026, 10, 25)), 10);
    final restored = Progress.decode(p.encode());
    expect(restored.coins, 90);
    expect(restored.loginDay, 1);
    expect(restored.claimLogin(DateTime(2026, 10, 25)), 0);
    restored.refreshDay(DateTime(2026, 10, 28));
    expect(restored.claimLogin(DateTime(2026, 10, 26)), 0);
    expect(restored.claimLogin(DateTime(2026, 10, 28)), 15);
  });
  test('報酬は問題ごとに一度、保存復元や一周後に重ねて付与しない', () {
    final p = Progress();
    final day = DateTime(2026, 10, 23);
    p.submit('さくら', now: day);
    expect(p.coins, 10);
    expect(p.lastReward, 10);
    final restored = Progress.decode(p.encode());
    expect(restored.coins, 10);
    expect(restored.submit('さくら', now: day), false);
    restored.next();
    restored.solved = legacyWords.length;
    restored.submit('さくら', now: day);
    expect(restored.coins, 10);
    expect(restored.dailyWords.length, 1);
    expect(restored.lastReward, 0);
  });
  test('異なる3問で日次30、一日一度、翌日リセット、時計逆戻りも二重取得しない', () {
    var p = Progress();
    final day = DateTime(2026, 10, 23);
    for (var i = 0; i < 4; i++) {
      p.submit(p.word.text, now: day);
      if (i == 2) {
        expect(p.lastDailyBonus, true);
        expect(p.coins, 60);
      }
      p = Progress.decode(p.encode());
      p.next();
    }
    expect(p.coins, 70);
    expect(p.dailyWords.length, 3);
    expect(p.dailyBonusGiven, true);
    p.refreshDay(DateTime(2026, 10, 24));
    expect(p.dailyWords, isEmpty);
    expect(p.dailyBonusGiven, false);
    p.refreshDay(day);
    expect(p.dailyDate, '2026-10-24');
    p.submit(p.word.text, now: day);
    expect(p.dailyWords, isEmpty);
    p.next();
    for (var i = 0; i < 3; i++) {
      p.solved = i;
      p.submit(p.word.text, now: DateTime(2026, 10, 24));
      p.next();
    }
    expect(p.coins, 110); // fifth initial clear + next day's capped bonus
    expect(p.dailyBonusGiven, true);
  });
  test('購入は一種類一度、残高不足と未知の商品を拒否し、森と残高を保存', () {
    final p = Progress(coins: 480, solved: 8);
    for (final item in forestItems) {
      expect(p.purchase(item.id), true);
      final balance = p.coins;
      expect(p.purchase(item.id), false);
      expect(p.coins, balance);
    }
    expect(p.coins, 0);
    expect(p.purchase('unknown'), false);
    final restored = Progress.decode(p.encode());
    expect(restored.ownedItems, forestItems.map((item) => item.id).toSet());
    expect(restored.coins, 0);
    expect(restored.totalSolved, 8);
    expect(Progress(coins: 29).purchase('tulip'), false);
  });
  test('森の飾りの配置位置を保存し、旧セーブは元の場所を保つ', () {
    final placed = Progress(
      ownedItems: {'tulip'},
      itemPositions: {
        'tulip': [.42, .68],
      },
    );
    expect(Progress.decode(placed.encode()).itemPositions['tulip'], [.42, .68]);

    final old = Progress.decode(
      '{"version":1,"solved":0,"guesses":[],"hints":0,"largeText":false,"ownedItems":["tulip"]}',
    );
    expect(old.ownedItems, {'tulip'});
    expect(old.itemPositions['tulip'], [.302, .95]);
  });
  test('森のエリアごとに解放状態・動物・相対配置を保存し、旧配置をエリア1へ移行する', () {
    final p = Progress(
      ownedItems: {'tulip'},
      itemPositions: {
        'tulip': [.42, .68],
      },
      forestAreas: {
        firstForestAreaId: ForestAreaProgress(
          unlocked: true,
          animals: {'rabbit', 'squirrel'},
          itemPositions: {
            'tulip': [.42, .68],
          },
        ),
        'forest_area_2': ForestAreaProgress(
          animals: {'owl'},
          itemPositions: {
            'tulip': [.26, .74],
          },
        ),
      },
    );
    final restored = Progress.decode(p.encode());
    expect(restored.forestAreaUnlocked(firstForestAreaId), isTrue);
    expect(restored.forestAreaUnlocked('forest_area_2'), isFalse);
    expect(restored.forestAnimalsFor(firstForestAreaId), {
      'rabbit',
      'squirrel',
    });
    expect(restored.forestAnimalsFor('forest_area_2'), {'owl'});
    expect(restored.itemPositions['tulip'], [.42, .68]);
    expect(
      restored.forestAreaProgress('forest_area_2').itemPositions['tulip'],
      [.26, .74],
    );
  });
  test('森飾りの大きさ・向き・花色はエリア別に保存し、売却時に消える', () {
    final p = Progress(
      coins: 40,
      ownedItems: {'tulip'},
      itemPositions: {
        'tulip': [.42, .68],
      },
      forestAreas: {
        firstForestAreaId: ForestAreaProgress(
          itemPositions: {
            'tulip': [.42, .68],
          },
          itemAppearances: {
            'tulip': const ForestItemAppearance(
              scale: 1.3,
              flipped: true,
              rotationSteps: 3,
              tint: 0xFFE8759C,
            ),
          },
        ),
        'forest_area_2': ForestAreaProgress(
          itemAppearances: {'tulip': const ForestItemAppearance(scale: .8)},
        ),
      },
    );
    final restored = Progress.decode(p.encode());
    expect(
      restored
          .forestAreaProgress(firstForestAreaId)
          .itemAppearances['tulip']!
          .encode(),
      const ForestItemAppearance(
        scale: 1.3,
        flipped: true,
        rotationSteps: 3,
        tint: 0xFFE8759C,
      ).encode(),
    );
    expect(
      restored
          .forestAreaProgress('forest_area_2')
          .itemAppearances['tulip']!
          .scale,
      .8,
    );
    expect(restored.sellForestItem('tulip'), 15);
    expect(restored.coins, 55);
    expect(
      restored.forestAreaProgress(firstForestAreaId).itemAppearances,
      isEmpty,
    );
  });
  test('森のおともだちは累計クリア数で解放され、一度のお知らせを保存する', () {
    final p = Progress(solved: 4);
    expect(p.forestFriends, {'rabbit'});
    p.solved = 5;
    expect(p.forestFriends, {'rabbit', 'squirrel'});
    expect(p.unannouncedForestFriends, ['squirrel']);
    p.forestFriendAnnouncements.add('squirrel');
    final restored = Progress.decode(p.encode());
    expect(restored.unannouncedForestFriends, isEmpty);
    restored.solved = 15;
    expect(restored.forestFriends, containsAll(['hedgehog', 'squirrel']));
    expect(restored.unannouncedForestFriends, ['hedgehog']);
    restored.solved = 50;
    expect(restored.unannouncedForestFriends, ['hedgehog', 'tanuki', 'fawn']);
  });
  test('以前の保存データを保ち、動きを減らす設定を保存する', () {
    final p = Progress.decode(
      '{"version":1,"solved":2,"guesses":["あいうう"],"hints":1,"largeText":true}',
    );
    expect(p.solved, 2);
    expect(p.guesses, ['あいうう']);
    expect(p.largeText, true);
    expect(p.reduceMotion, false);
    p.reduceMotion = true;
    expect(Progress.decode(p.encode()).reduceMotion, true);
    expect(Progress.decode(p.encode()).guesses, ['あいうう']);
  });
  test('重複文字は正しい位置を優先して個数を消費する', () {
    expect(judge('ここあ', 'こあこ'), [Match.exact, Match.present, Match.present]);
    expect(judge('さくら', 'さささ'), [Match.exact, Match.absent, Match.absent]);
    expect(judge('もも', 'もも'), [Match.exact, Match.exact]);
    expect(judge('さくら', 'くらげ'), [Match.present, Match.present, Match.absent]);
    expect(() => judge('もも', 'さくら'), throwsArgumentError);
  });
  test('入力検証、回数制限なし、正解時だけ次へ進む', () {
    final p = Progress();
    p.next();
    expect(p.solved, 0);
    expect(p.submit('abc'), false);
    expect(p.submit('さ'), false);
    for (var i = 0; i < 30; i++) {
      expect(p.submit('あいう'), true);
    }
    expect(p.submit(' サクラ '), true);
    expect(p.won, true);
    expect(p.totalSolved, 1);
    expect(p.submit('さくら'), false);
    p.next();
    expect(p.solved, 1);
    expect(p.guesses, isEmpty);
    expect(p.hints, 0);
  });
  test('保存から正解直後の成長、ヒント、設定を復元する', () {
    final p = Progress(hints: 2, largeText: true);
    p.submit('さくら');
    final restored = Progress.decode(p.encode());
    expect(restored.won, true);
    expect(restored.totalSolved, 1);
    expect(restored.hints, 2);
    expect(restored.largeText, true);
    restored.next();
    expect(Progress.decode(restored.encode()).solved, 1);
    expect(Progress.decode('broken').solved, 0);
  });
  test('問題は重複なし、全角ひらがな、ヒント付き', () {
    expect(words.map((w) => w.text).toSet().length, words.length);
    for (var i = 0; i < words.length; i++) {
      expect(RegExp(r'^[ぁ-ゖー]+$').hasMatch(words[i].text), true);
      expect(words[i].clue.isNotEmpty, true);
      expect(
        judge(words[i].text, words[i].text).every((m) => m == Match.exact),
        true,
      );
    }
    for (var i = 0; i < legacyWords.length; i++) {
      final p = Progress(solved: i);
      expect(p.submit(legacyWords[i].text), true);
      expect(p.won, true);
    }
    expect(
      Progress(solved: legacyWords.length).word.text,
      legacyWords.first.text,
    );
  });
}

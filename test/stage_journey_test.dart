import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/stage_journey.dart';

void main() {
  test('ステージクリアの報酬状態は再起動後も同じセッションに結びつく', () {
    final journey = StageJourney();
    final session = journey.start(1)!;
    expect(session.submit(session.answer), isTrue);
    session.clearRewardAmount = 20;
    session.clearRewardDate = '2026-10-25';
    journey.complete(session);

    final restored = StageJourney.decode(journey.encode());
    expect(restored.sessions[1]?.clearRewardAmount, 20);
    expect(restored.sessions[1]?.clearRewardDate, '2026-10-25');
  });

  test('10ステージを順に遊び、保存・再挑戦で最高評価と解放を保つ', () {
    var journey = StageJourney();
    expect(journey.start(2), isNull);

    for (final stage in forestStages) {
      final session = journey.start(stage.id);
      expect(session, isNotNull);
      expect(session!.word.text, stage.answer);
      for (var attempt = 0; attempt < 3; attempt++) {
        expect(session.submit('あ' * stage.answer.runes.length), isTrue);
      }
      expect(session.won, isFalse);
      expect(session.submit(stage.answer), isTrue);
      expect(journey.complete(session), isTrue);
      expect(journey.complete(session), isFalse);
      expect(journey.stars[stage.id], 2);
      expect(journey.unlocked(stage.id + 1), stage.id < forestStages.length);
      journey = StageJourney.decode(journey.encode());
    }

    expect(journey.cleared, forestStages.length);
    expect(journey.frontier, forestStages.last.id);
    expect(journey.unlocked(forestStages.last.id), isTrue);

    // Replaying stage 1 improves its best rating without disturbing later clears.
    final replay = journey.start(1)!;
    expect(replay.submit(replay.answer), isTrue);
    expect(journey.complete(replay), isTrue);
    expect(journey.stars[1], 3);
    expect(journey.cleared, forestStages.length);
  });
}

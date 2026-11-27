import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/game.dart';

void main() {
  test('初回20、同日1回だけ、翌日以降は2コインを保存して付与する', () {
    final progress = Progress(coins: 7);
    final day1 = DateTime(2026, 10, 25, 10);
    final day2 = DateTime(2026, 10, 26, 0);

    expect(
      progress.claimStageClearReward(1, day1, wasPreviouslyCleared: false),
      20,
    );
    expect(
      progress.claimStageClearReward(
        1,
        day1.add(const Duration(hours: 3)),
        wasPreviouslyCleared: true,
      ),
      0,
    );
    expect(progress.coins, 27);

    final restored = Progress.decode(progress.encode());
    expect(restored.coins, 27);
    expect(restored.stageRewardFor(1, day1), 20);
    expect(restored.claimStageAdReward(1, day1), isTrue);
    expect(restored.claimStageAdReward(1, day1), isFalse);
    expect(restored.coins, 47);
    expect(
      restored.claimStageClearReward(1, day2, wasPreviouslyCleared: true),
      2,
    );
    expect(restored.coins, 49);
    expect(
      restored.claimStageClearReward(1, day1, wasPreviouslyCleared: true),
      0,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/game.dart';

void main() {
  test('動画コインは1日1回で、再起動と時計戻しでも二重受取しない', () {
    final day = DateTime(2026, 10, 25);
    var progress = Progress(coins: 34);

    expect(progress.claimAdCoinReward(day), isTrue);
    expect(progress.coins, 44);
    expect(progress.claimAdCoinReward(day), isFalse);

    progress = Progress.decode(progress.encode());
    expect(progress.lastAdCoinRewardDate, '2026-10-25');
    expect(progress.claimAdCoinReward(day), isFalse);
    expect(
      progress.claimAdCoinReward(day.subtract(const Duration(days: 1))),
      isFalse,
    );
    expect(
      progress.claimAdCoinReward(day.add(const Duration(days: 1))),
      isTrue,
    );
    expect(progress.coins, 54);
  });
}

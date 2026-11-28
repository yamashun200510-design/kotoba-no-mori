import 'dart:convert';
import 'dart:math' as math;
import 'game.dart';
import 'invitation.dart';
import 'stage_areas.dart';
import 'stage_catalog.dart';

class ForestStage {
  final int id;
  final String answer;
  const ForestStage(this.id, this.answer);
  Word get word => words.firstWhere((word) => word.text == answer);
  ForestArea get areaInfo => areaOfStage(id);
  String get area => areaInfo.name;
}

// Stable IDs and answers (lib/stage_catalog.dart): stages 1-10 keep their
// original answers, and adding catalogue entries never moves a stage.
final List<ForestStage> forestStages = List.unmodifiable([
  for (var i = 0; i < stageAnswers.length; i++)
    ForestStage(i + 1, stageAnswers[i]),
]);

/// Reuses the existing unbounded guest puzzle, but supplies a catalogue word.
class StageSession extends InvitationPuzzle {
  final ForestStage stage;
  int clearRewardAmount = 0;
  String clearRewardDate = '';
  StageSession(this.stage) : super(stage.answer, hint: stage.word.clue);
  @override
  Word get word => stage.word;
}

class StageJourney {
  static const storageKey = 'forest_stage_journey_v1';
  final Map<int, int> stars = {};
  final Map<int, StageSession> sessions = {};
  int get cleared => stars.values.where((value) => value > 0).length;
  int get frontier => forestStages
      .firstWhere(
        (stage) => (stars[stage.id] ?? 0) == 0,
        orElse: () => forestStages.last,
      )
      .id;
  bool unlocked(int id) =>
      id >= 1 &&
      id <= forestStages.length &&
      (id == 1 || (stars[id - 1] ?? 0) > 0);
  static int rating(int attempts) => attempts <= 0
      ? 0
      : attempts <= 3
      ? 3
      : attempts <= 6
      ? 2
      : 1;
  StageSession? start(int id) {
    if (!unlocked(id)) return null;
    final old = sessions[id];
    if (old != null && !old.won) return old;
    final session = StageSession(forestStages[id - 1]);
    sessions[id] = session;
    return session;
  }

  bool complete(StageSession session) {
    if (!identical(sessions[session.stage.id], session) ||
        !session.won ||
        !unlocked(session.stage.id)) {
      return false;
    }
    final id = session.stage.id, best = stars[session.stage.id] ?? 0;
    stars[id] = math.max(best, rating(session.guesses.length));
    return stars[id] != best;
  }

  String encode() => jsonEncode({
    'version': 1,
    'stars': {for (final entry in stars.entries) '${entry.key}': entry.value},
    'sessions': {
      for (final entry in sessions.entries)
        '${entry.key}': {
          'answer': entry.value.answer,
          'guesses': entry.value.guesses,
          'draft': entry.value.draft,
          'clearRewardAmount': entry.value.clearRewardAmount,
          'clearRewardDate': entry.value.clearRewardDate,
        },
    },
  });
  factory StageJourney.decode(String? raw) {
    final journey = StageJourney();
    if (raw == null) return journey;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['version'] != 1) return journey;
      final scores = data['stars'] as Map<String, dynamic>? ?? {};
      for (final stage in forestStages) {
        final value = scores['${stage.id}'];
        if (value is int &&
            value >= 1 &&
            value <= 3 &&
            journey.unlocked(stage.id)) {
          journey.stars[stage.id] = value;
        }
      }
      final saved = data['sessions'] as Map<String, dynamic>? ?? {};
      for (final stage in forestStages) {
        final item = saved['${stage.id}'];
        if (item is! Map ||
            item['answer'] != stage.answer ||
            !journey.unlocked(stage.id)) {
          continue;
        }
        final session = StageSession(stage);
        var valid = true;
        for (final guess in (item['guesses'] as List).cast<String>()) {
          if (!session.submit(guess)) {
            valid = false;
            break;
          }
        }
        final draft = item['draft'] as String? ?? '';
        if (valid &&
            draft.runes.length <= stage.answer.runes.length &&
            (draft.isEmpty || RegExp(r'^[ぁ-ゖー]+$').hasMatch(draft))) {
          session.draft = draft;
          final rewardAmount = item['clearRewardAmount'];
          final rewardDate = item['clearRewardDate'];
          if ((rewardAmount == 0 || rewardAmount == 2 || rewardAmount == 20) &&
              rewardDate is String &&
              (rewardDate.isEmpty ||
                  RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rewardDate))) {
            session.clearRewardAmount = rewardAmount as int;
            session.clearRewardDate = rewardDate;
          }
          journey.sessions[stage.id] = session;
        }
      }
    } catch (_) {
      // A damaged stage save never resets the separate normal-game save.
    }
    return journey;
  }
  StageJourney();
}

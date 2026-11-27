/// Local answer records. No account, remote averages or network dependencies.
class PuzzleRecord {
  final int id, length, attempts;
  final String word, date, source;
  const PuzzleRecord({
    required this.id,
    required this.word,
    required this.length,
    required this.attempts,
    required this.date,
    required this.source,
  });
  Map<String, dynamic> encode() => {
    'id': id,
    'word': word,
    'length': length,
    'attempts': attempts,
    'date': date,
    'source': source,
  };
  static List<PuzzleRecord> decodeList(dynamic data) {
    final result = <PuzzleRecord>[];
    if (data is! List) return result;
    final ids = <int>{};
    for (final value in data) {
      try {
        final record = PuzzleRecord(
          id: value['id'] as int,
          word: value['word'] as String,
          length: value['length'] as int,
          attempts: value['attempts'] as int,
          date: value['date'] as String,
          source: value['source'] as String,
        );
        if (record.id < 1 ||
            record.attempts < 1 ||
            record.word.runes.length != record.length ||
            !RegExp(r'^[ぁ-ゖー]+$').hasMatch(record.word) ||
            !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(record.date) ||
            !['normal', 'daily', 'legacy'].contains(record.source) ||
            !ids.add(record.id)) {
          continue;
        }
        result.add(record);
      } catch (_) {
        // A damaged optional record must not reset coins or puzzle progress.
      }
    }
    return result;
  }
}

class PuzzleStatistics {
  final int clears, totalAttempts;
  const PuzzleStatistics(this.clears, this.totalAttempts);
  double? get averageAttempts => clears == 0 ? null : totalAttempts / clears;
  // Unlimited attempts: a wrong guess is never a lost or ended puzzle.
  // No streak-breaking event exists in the current game rules.
  int get streak => clears;
  int get bestStreak => streak;
  factory PuzzleStatistics.fromRecords(
    Iterable<PuzzleRecord> records, [
    int? length,
  ]) {
    final matching = records.where((r) => length == null || r.length == length);
    return PuzzleStatistics(
      matching.length,
      matching.fold(0, (sum, r) => sum + r.attempts),
    );
  }
}

/// Read-only view of the saved local ledger. Aggregation stays outside widgets.
class PlayerPerformance {
  final List<PuzzleRecord> records;
  final Set<String> dailyClearDates;
  final int lifetimeClears;
  PlayerPerformance(
    Iterable<PuzzleRecord> records,
    Iterable<String> dailyDates,
    this.lifetimeClears,
  ) : records = List.unmodifiable(records),
      dailyClearDates = Set.unmodifiable(dailyDates);
  PuzzleStatistics get overall => PuzzleStatistics.fromRecords(records);
  PuzzleStatistics forLength(int length) =>
      PuzzleStatistics.fromRecords(records, length);
  List<String> get dailyDatesNewestFirst =>
      dailyClearDates.toList()..sort((a, b) => b.compareTo(a));
  PuzzleRecord? dailyRecord(String date) {
    for (final record in records) {
      if (record.source == 'daily' && record.date == date) return record;
    }
    return null;
  }
}

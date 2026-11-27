/// Calendar boundaries, not rolling 24-hour cooldowns. Callers supply local time.
class LocalDay {
  static String key(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  static DateTime nextMidnight(DateTime now) => now.isUtc
      ? DateTime.utc(now.year, now.month, now.day + 1)
      : DateTime(now.year, now.month, now.day + 1);
  static int number(String date) => DateTime.parse('${date.isEmpty ? '1970-01-01' : date}T00:00:00Z')
      .millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}
